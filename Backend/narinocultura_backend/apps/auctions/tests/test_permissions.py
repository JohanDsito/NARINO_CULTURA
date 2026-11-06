from datetime import timedelta
from decimal import Decimal

from django.utils import timezone
from rest_framework.test import APITestCase

from apps.auctions.models import Auction
from tests.factories import AdminUserFactory, ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory


class AuctionEditPermissionTests(APITestCase):
    """HU-B02: solo el vendedor o un administrador modifican una subasta, y solo si está PENDIENTE."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller)
        self.other_artist = ArtistUserFactory()
        self.other_profile = ArtistProfileFactory(user=self.other_artist)
        self.buyer = UserFactory()
        self.admin = AdminUserFactory()
        self.pending = self._auction(Auction.Status.PENDIENTE)
        self.active = self._auction(Auction.Status.ACTIVA, artwork_status="EN_SUBASTA")

    def _auction(self, status, artwork_status="DISPONIBLE"):
        now = timezone.now()
        return Auction.objects.create(
            artwork=ArtworkFactory(artist=self.profile, status=artwork_status),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now + timedelta(hours=1),
            ends_at=now + timedelta(days=2),
            status=status,
        )

    def _url(self, auction):
        return f"/api/v1/auctions/{auction.id}/"

    def _patch(self, user, auction, data):
        self.client.force_authenticate(user=user)
        return self.client.patch(self._url(auction), data, format="json")

    def _delete(self, user, auction):
        self.client.force_authenticate(user=user)
        return self.client.delete(self._url(auction))

    # --- otros usuarios -------------------------------------------------------

    def test_other_user_cannot_edit_active_auction(self):
        for user in (self.buyer, self.other_artist):
            r = self._patch(user, self.active, {"ends_at": (timezone.now() + timedelta(minutes=1)).isoformat()})
            self.assertEqual(r.status_code, 403, user.role)
        self.active.refresh_from_db()
        self.assertGreater(self.active.ends_at, timezone.now() + timedelta(days=1))

    def test_other_user_cannot_delete_active_auction(self):
        r = self._delete(self.buyer, self.active)
        self.assertEqual(r.status_code, 403)
        self.assertTrue(Auction.objects.filter(id=self.active.id).exists())

    def test_other_user_does_not_see_foreign_pending_auction(self):
        self.assertEqual(self._patch(self.buyer, self.pending, {"base_price": "1.00"}).status_code, 404)
        self.assertEqual(self._delete(self.buyer, self.pending).status_code, 404)

    def test_anonymous_cannot_edit_or_delete(self):
        self.assertEqual(self.client.patch(self._url(self.active), {"base_price": "1.00"}, format="json").status_code, 401)
        self.assertEqual(self.client.delete(self._url(self.active)).status_code, 401)

    # --- vendedor ---------------------------------------------------------------

    def test_seller_can_edit_pending_auction_and_current_price_follows(self):
        r = self._patch(self.seller, self.pending, {"base_price": "150000.00"})
        self.assertEqual(r.status_code, 200)
        self.pending.refresh_from_db()
        self.assertEqual(self.pending.base_price, Decimal("150000.00"))
        self.assertEqual(self.pending.current_price, Decimal("150000.00"))

    def test_seller_can_delete_pending_auction(self):
        self.assertEqual(self._delete(self.seller, self.pending).status_code, 204)
        self.assertFalse(Auction.objects.filter(id=self.pending.id).exists())

    def test_seller_cannot_edit_or_delete_active_auction(self):
        r = self._patch(self.seller, self.active, {"base_price": "1.00"})
        self.assertEqual(r.status_code, 400)
        self.assertIn("PENDIENTE", r.data["detail"])
        self.assertEqual(self._delete(self.seller, self.active).status_code, 400)
        self.active.refresh_from_db()
        self.assertEqual(self.active.base_price, Decimal("100000.00"))

    def test_seller_cannot_swap_artwork(self):
        foreign = ArtworkFactory(artist=self.other_profile, status="DISPONIBLE")
        r = self._patch(self.seller, self.pending, {"artwork": str(foreign.id)})
        self.assertEqual(r.status_code, 400)
        self.pending.refresh_from_db()
        self.assertNotEqual(self.pending.artwork_id, foreign.id)

    def test_partial_update_validates_dates_against_saved_values(self):
        r = self._patch(self.seller, self.pending, {"ends_at": timezone.now().isoformat()})
        self.assertEqual(r.status_code, 400)

    def test_status_is_read_only(self):
        r = self._patch(self.seller, self.pending, {"status": "ACTIVA"})
        self.assertEqual(r.status_code, 200)
        self.pending.refresh_from_db()
        self.assertEqual(self.pending.status, Auction.Status.PENDIENTE)

    # --- administrador ----------------------------------------------------------

    def test_admin_can_edit_pending_auction(self):
        r = self._patch(self.admin, self.pending, {"base_price": "120000.00"})
        self.assertEqual(r.status_code, 200)

    def test_admin_cannot_delete_active_auction(self):
        self.assertEqual(self._delete(self.admin, self.active).status_code, 400)
        self.assertTrue(Auction.objects.filter(id=self.active.id).exists())
