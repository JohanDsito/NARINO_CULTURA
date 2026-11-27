import uuid
from datetime import timedelta
from decimal import Decimal

from asgiref.sync import async_to_sync, sync_to_async
from channels.layers import get_channel_layer
from channels.routing import URLRouter
from channels.testing import WebsocketCommunicator
from django.test import TransactionTestCase
from django.utils import timezone

from apps.artworks.models import Artwork
from apps.auctions.models import Auction
from config.routing import websocket_urlpatterns
from services.auction_service import AuctionService
from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory

APPLICATION = URLRouter(websocket_urlpatterns)
# Margen holgado para runners lentos (con cobertura); un test que pasa no espera este tiempo
TIMEOUT = 5


class AuctionConsumerTests(TransactionTestCase):
    """Consumer WebSocket de subastas: conexión, snapshot, eventos del servicio y desconexión."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        profile = ArtistProfileFactory(user=self.seller)
        self.bidder = UserFactory()
        now = timezone.now()
        self.auction = Auction.objects.create(
            artwork=ArtworkFactory(artist=profile, status=Artwork.Status.EN_SUBASTA),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now - timedelta(hours=1),
            ends_at=now + timedelta(hours=24),
            status=Auction.Status.ACTIVA,
        )

    def _communicator(self, auction_id):
        return WebsocketCommunicator(APPLICATION, f"/ws/auctions/{auction_id}/")

    def test_connect_sends_connected_and_snapshot(self):
        async def scenario():
            comm = self._communicator(self.auction.id)
            connected, _ = await comm.connect(TIMEOUT)
            self.assertTrue(connected)
            hello = await comm.receive_json_from(TIMEOUT)
            snapshot = await comm.receive_json_from(TIMEOUT)
            await comm.disconnect()
            return hello, snapshot

        hello, snapshot = async_to_sync(scenario)()
        self.assertEqual(hello, {"type": "connected", "auction_id": str(self.auction.id)})
        self.assertEqual(snapshot["type"], "snapshot")
        self.assertEqual(snapshot["current_price"], "100000.00")
        self.assertIsNone(snapshot["highest_bidder_id"])
        self.assertEqual(snapshot["status"], Auction.Status.ACTIVA)
        self.assertEqual(snapshot["ends_at"], self.auction.ends_at.isoformat())

    def test_snapshot_includes_highest_bidder(self):
        AuctionService.place_bid(auction=self.auction, bidder=self.bidder, amount=Decimal("120000.00"))

        async def scenario():
            comm = self._communicator(self.auction.id)
            await comm.connect(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            snapshot = await comm.receive_json_from(TIMEOUT)
            await comm.disconnect()
            return snapshot

        snapshot = async_to_sync(scenario)()
        self.assertEqual(snapshot["highest_bidder_id"], str(self.bidder.id))
        self.assertEqual(snapshot["current_price"], "120000.00")

    def test_unknown_auction_connects_without_snapshot(self):
        async def scenario():
            comm = self._communicator(uuid.uuid4())
            connected, _ = await comm.connect(TIMEOUT)
            hello = await comm.receive_json_from(TIMEOUT)
            nothing = await comm.receive_nothing()
            await comm.disconnect()
            return connected, hello, nothing

        connected, hello, nothing = async_to_sync(scenario)()
        self.assertTrue(connected)
        self.assertEqual(hello["type"], "connected")
        self.assertTrue(nothing)

    def test_bid_event_is_pushed_to_subscribed_client(self):
        async def scenario():
            comm = self._communicator(self.auction.id)
            await comm.connect(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            await sync_to_async(AuctionService.place_bid)(
                auction=self.auction, bidder=self.bidder, amount=Decimal("130000.00")
            )
            event = await comm.receive_json_from(TIMEOUT)
            await comm.disconnect()
            return event

        event = async_to_sync(scenario)()
        self.assertEqual(event["type"], "bid_placed")
        self.assertEqual(event["auction_id"], str(self.auction.id))
        self.assertEqual(event["amount"], "130000.00")
        self.assertEqual(event["current_price"], "130000.00")
        self.assertEqual(event["highest_bidder_id"], str(self.bidder.id))

    def test_close_event_is_pushed_and_other_auctions_are_isolated(self):
        async def scenario():
            comm = self._communicator(self.auction.id)
            other = self._communicator(uuid.uuid4())
            await comm.connect(TIMEOUT)
            await other.connect(TIMEOUT)
            for c in (comm, other):
                await c.receive_json_from(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            await sync_to_async(AuctionService.close_auction)(auction=self.auction, actor=self.seller)
            event = await comm.receive_json_from(TIMEOUT)
            other_silent = await other.receive_nothing()
            await comm.disconnect()
            await other.disconnect()
            return event, other_silent

        event, other_silent = async_to_sync(scenario)()
        self.assertEqual(event["type"], "auction_closed")
        self.assertEqual(event["auction_id"], str(self.auction.id))
        self.assertIsNone(event["winner_id"])  # cerrada sin pujas: no hay ganador
        self.assertEqual(event["current_price"], "100000.00")
        self.assertTrue(other_silent)

    def test_client_messages_are_ignored(self):
        async def scenario():
            comm = self._communicator(self.auction.id)
            await comm.connect(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            await comm.send_json_to({"type": "bid", "amount": "999"})
            silent = await comm.receive_nothing()
            await comm.disconnect()
            return silent

        self.assertTrue(async_to_sync(scenario)())
        self.auction.refresh_from_db()
        self.assertEqual(self.auction.current_price, Decimal("100000.00"))
        self.assertFalse(self.auction.bids.exists())

    def test_disconnect_leaves_the_group(self):
        group = f"auction_{self.auction.id}"

        async def scenario():
            comm = self._communicator(self.auction.id)
            await comm.connect(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            await comm.receive_json_from(TIMEOUT)
            layer = get_channel_layer()
            before = len(layer.groups.get(group, {}))
            await comm.disconnect()
            after = len(layer.groups.get(group, {}))
            return before, after

        before, after = async_to_sync(scenario)()
        self.assertEqual(before, 1)
        self.assertEqual(after, 0)
