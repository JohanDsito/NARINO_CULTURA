from datetime import timedelta
from decimal import Decimal

from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import AccessToken

from apps.auctions.models import Auction, Bid
from apps.artworks.models import Artwork
from services.auction_service import AuctionService
from tests.factories import AdminUserFactory, ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory


def auth_header(user):
    token = AccessToken.for_user(user)
    return {"HTTP_AUTHORIZATION": f"Bearer {token}"}


@override_settings(CHANNEL_LAYERS={"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}})
class AuctionServiceTests(APITestCase):
    def setUp(self):
        self.artist_user = ArtistUserFactory()
        self.artist_user.is_verified = True
        self.artist_user.save()
        self.profile = ArtistProfileFactory(user=self.artist_user)
        self.artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")
        self.buyer = UserFactory(role="COMPRADOR")
        self.buyer.is_verified = True
        self.buyer.save()

        self.auction = AuctionService.create_auction(
            seller=self.artist_user,
            artwork=self.artwork,
            base_price=Decimal("100000.00"),
            starts_at=timezone.now() - timedelta(hours=1),
            ends_at=timezone.now() + timedelta(hours=24),
        )

    def test_create_auction_sets_artwork_en_subasta(self):
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.status, Artwork.Status.EN_SUBASTA)
        self.assertEqual(self.auction.status, Auction.Status.ACTIVA)

    def test_place_bid_updates_current_price(self):
        bid = AuctionService.place_bid(
            auction=self.auction,
            bidder=self.buyer,
            amount=Decimal("120000.00"),
        )
        self.auction.refresh_from_db()
        self.assertEqual(self.auction.current_price, Decimal("120000.00"))
        self.assertEqual(self.auction.highest_bidder_id, self.buyer.id)
        self.assertIsInstance(bid, Bid)

    def test_bid_lower_than_current_price_fails(self):
        with self.assertRaises(ValueError):
            AuctionService.place_bid(
                auction=self.auction,
                bidder=self.buyer,
                amount=Decimal("50000.00"),
            )

    def test_close_auction_sets_winner(self):
        AuctionService.place_bid(auction=self.auction, bidder=self.buyer, amount=Decimal("150000.00"))
        closed = AuctionService.close_auction(auction=self.auction, actor=self.artist_user)
        self.assertEqual(closed.status, Auction.Status.CERRADA)
        self.assertEqual(closed.winner_id, self.buyer.id)

    def test_close_auction_without_bids_resets_artwork(self):
        closed = AuctionService.close_auction(auction=self.auction, actor=self.artist_user)
        self.artwork.refresh_from_db()
        self.assertEqual(closed.winner_id, None)
        self.assertEqual(self.artwork.status, Artwork.Status.DISPONIBLE)


@override_settings(CHANNEL_LAYERS={"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}})
class AuctionExpiredTaskTests(APITestCase):
    def test_close_expired_auctions_task(self):
        artist = ArtistUserFactory()
        artist.is_verified = True
        artist.save()
        profile = ArtistProfileFactory(user=artist)
        artwork = ArtworkFactory(artist=profile, status="DISPONIBLE")

        auction = Auction.objects.create(
            artwork=artwork,
            seller=artist,
            base_price=Decimal("50000.00"),
            current_price=Decimal("50000.00"),
            starts_at=timezone.now() - timedelta(hours=2),
            ends_at=timezone.now() - timedelta(minutes=5),
            status=Auction.Status.ACTIVA,
        )

        AuctionService._close_if_ended(auction_id=auction.id)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.CERRADA)

    def test_not_expired_auction_not_closed(self):
        artist = ArtistUserFactory()
        artist.is_verified = True
        artist.save()
        profile = ArtistProfileFactory(user=artist)
        artwork = ArtworkFactory(artist=profile, status="DISPONIBLE")

        auction = Auction.objects.create(
            artwork=artwork,
            seller=artist,
            base_price=Decimal("50000.00"),
            current_price=Decimal("50000.00"),
            starts_at=timezone.now() - timedelta(hours=1),
            ends_at=timezone.now() + timedelta(hours=10),
            status=Auction.Status.ACTIVA,
        )

        AuctionService._close_if_ended(auction_id=auction.id)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)


class AuctionVisibilityTests(APITestCase):
    def setUp(self):
        self.seller = ArtistUserFactory()
        profile = ArtistProfileFactory(user=self.seller)
        now = timezone.now()
        self.pending = Auction.objects.create(
            artwork=ArtworkFactory(artist=profile),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now,
            ends_at=now + timedelta(days=1),
            status=Auction.Status.PENDIENTE,
        )
        self.active = Auction.objects.create(
            artwork=ArtworkFactory(artist=profile, status="EN_SUBASTA"),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now,
            ends_at=now + timedelta(days=1),
            status=Auction.Status.ACTIVA,
        )

    def _ids(self, response):
        data = response.data["results"] if isinstance(response.data, dict) else response.data
        return {a["id"] for a in data}

    def test_public_does_not_see_pending_auctions(self):
        r = self.client.get("/api/v1/auctions/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(self._ids(r), {str(self.active.id)})
        self.assertEqual(self.client.get(f"/api/v1/auctions/{self.pending.id}/").status_code, 404)

    def test_seller_sees_own_pending_auction(self):
        self.client.force_authenticate(user=self.seller)
        r = self.client.get("/api/v1/auctions/")
        self.assertEqual(self._ids(r), {str(self.active.id), str(self.pending.id)})

    def test_admin_sees_pending_auctions(self):
        self.client.force_authenticate(user=AdminUserFactory())
        r = self.client.get("/api/v1/auctions/", {"status": "PENDIENTE"})
        self.assertEqual(self._ids(r), {str(self.pending.id)})

    def test_filter_by_status(self):
        r = self.client.get("/api/v1/auctions/", {"status": "ACTIVA"})
        self.assertEqual(self._ids(r), {str(self.active.id)})
        r = self.client.get("/api/v1/auctions/", {"status": "CERRADA"})
        self.assertEqual(self._ids(r), set())
