from datetime import timedelta
from decimal import Decimal

from django.utils import timezone
from rest_framework.test import APIRequestFactory, APITestCase

from apps.artworks.models import Artwork
from apps.auctions.models import Auction, Bid
from apps.auctions.permissions import IsAuctionSellerOrAdmin
from tests.factories import AdminUserFactory, ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory

URL = "/api/v1/auctions/"


class AuctionApiTestCase(APITestCase):
    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller)
        self.admin = AdminUserFactory()
        self.buyer = UserFactory()

    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def _auction(self, status=Auction.Status.ACTIVA, artwork_status=Artwork.Status.EN_SUBASTA):
        now = timezone.now()
        return Auction.objects.create(
            artwork=ArtworkFactory(artist=self.profile, status=artwork_status),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now - timedelta(hours=1),
            ends_at=now + timedelta(days=1),
            status=status,
        )

    def _pending(self):
        return self._auction(Auction.Status.PENDIENTE, artwork_status=Artwork.Status.DISPONIBLE)


class CreateAuctionApiTests(AuctionApiTestCase):
    def payload(self, artwork, **overrides):
        start = timezone.now() + timedelta(hours=1)
        data = {
            "artwork": str(artwork.id),
            "base_price": "120000.00",
            "starts_at": start.isoformat(),
            "ends_at": (start + timedelta(days=2)).isoformat(),
        }
        data.update(overrides)
        return data

    def test_artist_creates_pending_auction(self):
        artwork = ArtworkFactory(artist=self.profile)
        r = self.as_user(self.seller).post(URL, self.payload(artwork), format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["status"], Auction.Status.PENDIENTE)
        self.assertEqual(r.data["current_price"], "120000.00")
        self.assertEqual(Auction.objects.get(id=r.data["id"]).seller, self.seller)

    def test_artist_cannot_auction_foreign_artwork(self):
        foreign = ArtworkFactory()
        r = self.as_user(self.seller).post(URL, self.payload(foreign), format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("propias obras", r.data["detail"])
        self.assertFalse(Auction.objects.exists())

    def test_buyer_cannot_create_auction(self):
        artwork = ArtworkFactory(artist=self.profile)
        r = self.as_user(self.buyer).post(URL, self.payload(artwork), format="json")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(Auction.objects.exists())

    def test_anonymous_cannot_create_auction(self):
        artwork = ArtworkFactory(artist=self.profile)
        self.assertEqual(self.client.post(URL, self.payload(artwork), format="json").status_code, 401)

    def test_base_price_must_be_positive(self):
        artwork = ArtworkFactory(artist=self.profile)
        r = self.as_user(self.seller).post(URL, self.payload(artwork, base_price="0.00"), format="json")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(Auction.objects.exists())


class BidApiTests(AuctionApiTestCase):
    def test_buyer_places_bid(self):
        auction = self._auction()
        r = self.as_user(self.buyer).post(f"{URL}{auction.id}/bid/", {"amount": "150000.00"}, format="json")
        self.assertEqual(r.status_code, 201)
        bid = Bid.objects.get(id=r.data["bid_id"])
        self.assertEqual(bid.bidder, self.buyer)
        auction.refresh_from_db()
        self.assertEqual(auction.current_price, Decimal("150000.00"))
        self.assertEqual(auction.highest_bidder, self.buyer)

    def test_anonymous_cannot_bid(self):
        auction = self._auction()
        r = self.client.post(f"{URL}{auction.id}/bid/", {"amount": "150000.00"}, format="json")
        self.assertEqual(r.status_code, 401)
        self.assertFalse(Bid.objects.exists())

    def test_amount_is_required(self):
        auction = self._auction()
        r = self.as_user(self.buyer).post(f"{URL}{auction.id}/bid/", {}, format="json")
        self.assertEqual(r.status_code, 400)


class CloseApiTests(AuctionApiTestCase):
    def test_seller_closes_auction(self):
        auction = self._auction()
        r = self.as_user(self.seller).post(f"{URL}{auction.id}/close/")
        self.assertEqual(r.status_code, 200)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.CERRADA)

    def test_other_user_cannot_close(self):
        auction = self._auction()
        r = self.as_user(self.buyer).post(f"{URL}{auction.id}/close/")
        self.assertEqual(r.status_code, 400)
        self.assertIn("permisos", r.data["detail"])
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)

    def test_anonymous_cannot_close(self):
        auction = self._auction()
        self.assertEqual(self.client.post(f"{URL}{auction.id}/close/").status_code, 401)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)


class ModerationApiTests(AuctionApiTestCase):
    def test_admin_approves_pending_auction(self):
        auction = self._pending()
        r = self.as_user(self.admin).post(f"{URL}{auction.id}/approve/")
        self.assertEqual(r.status_code, 200)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)
        self.assertEqual(auction.artwork.status, Artwork.Status.EN_SUBASTA)

    def test_approving_active_auction_fails(self):
        auction = self._auction()
        r = self.as_user(self.admin).post(f"{URL}{auction.id}/approve/")
        self.assertEqual(r.status_code, 400)

    def test_admin_rejects_pending_auction(self):
        auction = self._pending()
        r = self.as_user(self.admin).post(f"{URL}{auction.id}/reject/")
        self.assertEqual(r.status_code, 200)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.CANCELADA)

    def test_rejecting_active_auction_fails(self):
        auction = self._auction()
        r = self.as_user(self.admin).post(f"{URL}{auction.id}/reject/")
        self.assertEqual(r.status_code, 400)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)

    def test_seller_cannot_moderate_own_auction(self):
        auction = self._pending()
        self.assertEqual(self.as_user(self.seller).post(f"{URL}{auction.id}/approve/").status_code, 403)
        self.assertEqual(self.as_user(self.seller).post(f"{URL}{auction.id}/reject/").status_code, 403)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.PENDIENTE)


class AuctionSellerPermissionTests(AuctionApiTestCase):
    """Permiso de objeto: lectura libre; escritura solo del vendedor o del administrador."""

    def _check(self, method, user, auction):
        request = getattr(APIRequestFactory(), method)("/")
        request.user = user
        return IsAuctionSellerOrAdmin().has_object_permission(request, None, auction)

    def test_read_is_allowed_to_anyone(self):
        self.assertTrue(self._check("get", self.buyer, self._auction()))

    def test_write_only_for_seller_or_admin(self):
        auction = self._auction()
        self.assertTrue(self._check("patch", self.seller, auction))
        self.assertTrue(self._check("delete", self.admin, auction))
        self.assertFalse(self._check("patch", self.buyer, auction))


class AuctionStrTests(AuctionApiTestCase):
    def test_str_shows_status_and_amount(self):
        auction = self._auction()
        bid = Bid.objects.create(auction=auction, bidder=self.buyer, amount=Decimal("150000.00"))
        self.assertIn("ACTIVA", str(auction))
        self.assertIn("150000.00", str(bid))
