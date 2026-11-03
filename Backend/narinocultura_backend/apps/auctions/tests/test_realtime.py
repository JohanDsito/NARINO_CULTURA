from datetime import timedelta
from decimal import Decimal
from unittest.mock import patch

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.artworks.models import Artwork
from apps.auctions.models import Auction
from apps.auctions.tasks import close_expired_auctions
from apps.notifications.models import NotificationLog
from services.auction_service import AuctionService
from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory


class AuctionRealtimeTests(TestCase):
    """HU-B03 y HU-B06: contrato WebSocket, emisión tras el commit, cierre automático y reglas de puja."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller)
        self.bidder = UserFactory(first_name="Ana", last_name="Pérez")
        self.auction = self._auction()

    def _auction(self, *, starts=-1, ends=24):
        now = timezone.now()
        return Auction.objects.create(
            artwork=ArtworkFactory(artist=self.profile, status=Artwork.Status.EN_SUBASTA),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now + timedelta(hours=starts),
            ends_at=now + timedelta(hours=ends),
            status=Auction.Status.ACTIVA,
        )

    def _payloads(self, mock):
        return [c.kwargs["payload"] for c in mock.call_args_list]

    # --- contrato de eventos ----------------------------------------------------

    def test_bid_emits_bid_placed_with_web_and_mobile_fields(self):
        with patch.object(AuctionService, "_broadcast") as broadcast, self.captureOnCommitCallbacks(execute=True):
            AuctionService.place_bid(auction=self.auction, bidder=self.bidder, amount=Decimal("120000.00"))
        (payload,) = self._payloads(broadcast)
        self.assertEqual(payload["type"], "bid_placed")
        self.assertEqual(payload["current_price"], "120000.00")
        self.assertEqual(payload["amount"], "120000.00")
        self.assertEqual(payload["highest_bidder_id"], str(self.bidder.id))
        self.assertEqual(payload["bidder_name"], "Ana P.")
        self.assertIn("ends_at", payload)

    def test_manual_close_emits_auction_closed(self):
        AuctionService.place_bid(auction=self.auction, bidder=self.bidder, amount=Decimal("120000.00"))
        with patch.object(AuctionService, "_broadcast") as broadcast, self.captureOnCommitCallbacks(execute=True):
            AuctionService.close_auction(auction=self.auction, actor=self.seller)
        (payload,) = self._payloads(broadcast)
        self.assertEqual(payload["type"], "auction_closed")
        self.assertEqual(payload["winner_id"], str(self.bidder.id))
        self.assertEqual(payload["current_price"], "120000.00")

    def test_event_reaches_clients_subscribed_to_the_auction_group(self):
        layer = get_channel_layer()
        channel = async_to_sync(layer.new_channel)()
        async_to_sync(layer.group_add)(f"auction_{self.auction.id}", channel)
        with self.captureOnCommitCallbacks(execute=True):
            AuctionService.place_bid(auction=self.auction, bidder=self.bidder, amount=Decimal("130000.00"))
        message = async_to_sync(layer.receive)(channel)
        self.assertEqual(message["type"], "auction_event")
        self.assertEqual(message["payload"]["type"], "bid_placed")
        async_to_sync(layer.group_discard)(f"auction_{self.auction.id}", channel)

    def test_no_event_when_transaction_rolls_back(self):
        with patch.object(AuctionService, "_broadcast") as broadcast, self.captureOnCommitCallbacks(execute=True):
            try:
                with transaction.atomic():
                    AuctionService.place_bid(auction=self.auction, bidder=self.bidder, amount=Decimal("120000.00"))
                    raise RuntimeError("fallo posterior")
            except RuntimeError:
                pass
        broadcast.assert_not_called()
        self.auction.refresh_from_db()
        self.assertEqual(self.auction.current_price, Decimal("100000.00"))

    # --- cierre automático ----------------------------------------------------------

    def test_automatic_close_emits_event_and_notifies_winner(self):
        AuctionService.place_bid(auction=self.auction, bidder=self.bidder, amount=Decimal("120000.00"))
        Auction.objects.filter(id=self.auction.id).update(ends_at=timezone.now() - timedelta(minutes=1))
        with patch.object(AuctionService, "_broadcast") as broadcast, self.captureOnCommitCallbacks(execute=True):
            close_expired_auctions()
        self.auction.refresh_from_db()
        self.assertEqual(self.auction.status, Auction.Status.CERRADA)
        self.assertEqual(self.auction.winner_id, self.bidder.id)
        (payload,) = self._payloads(broadcast)
        self.assertEqual(payload["type"], "auction_closed")
        log = NotificationLog.objects.get(notification_type="AUCTION_CLOSED")
        self.assertEqual(log.payload["winner_email"], self.bidder.email)

    def test_bid_on_expired_auction_closes_it(self):
        """Antes el cierre se revertía junto con el error de la puja."""
        expired = self._auction(starts=-48, ends=-1)
        with self.assertRaisesMessage(ValueError, "finalizó"):
            AuctionService.place_bid(auction=expired, bidder=self.bidder, amount=Decimal("500000.00"))
        expired.refresh_from_db()
        self.assertEqual(expired.status, Auction.Status.CERRADA)
        self.assertFalse(expired.bids.exists())

    # --- reglas de puja (HU-B06) ------------------------------------------------------

    def test_seller_cannot_bid_on_own_auction(self):
        with self.assertRaisesMessage(ValueError, "propia subasta"):
            AuctionService.place_bid(auction=self.auction, bidder=self.seller, amount=Decimal("200000.00"))
        self.assertFalse(self.auction.bids.exists())

    def test_status_is_checked_on_the_locked_row(self):
        """Una instancia desactualizada (ACTIVA en memoria, CERRADA en BD) no permite pujar."""
        stale = Auction.objects.get(id=self.auction.id)
        Auction.objects.filter(id=self.auction.id).update(status=Auction.Status.CERRADA)
        with self.assertRaisesMessage(ValueError, "no está activa"):
            AuctionService.place_bid(auction=stale, bidder=self.bidder, amount=Decimal("200000.00"))

    def test_price_is_checked_on_the_locked_row(self):
        stale = Auction.objects.get(id=self.auction.id)
        AuctionService.place_bid(auction=self.auction, bidder=UserFactory(), amount=Decimal("150000.00"))
        with self.assertRaisesMessage(ValueError, "mayor al precio actual"):
            AuctionService.place_bid(auction=stale, bidder=self.bidder, amount=Decimal("120000.00"))

    def test_bid_api_rejects_seller(self):
        client = APIClient()
        client.force_authenticate(user=self.seller)
        r = client.post(f"/api/v1/auctions/{self.auction.id}/bid/", {"amount": "200000.00"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("propia subasta", r.data["detail"])
