from datetime import timedelta
from decimal import Decimal

from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.artworks.models import Artwork
from apps.auctions.models import Auction
from apps.auctions.tasks import close_expired_auctions, expire_unpaid_auction_orders
from apps.marketplace.models import Order
from apps.notifications.models import NotificationLog
from services.auction_service import AuctionService
from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory


@override_settings(AUCTION_PAYMENT_HOURS=48)
class AuctionWinnerPaymentTests(APITestCase):
    """HU-B04 (RF17, RF21): el ganador recibe una orden de pago con plazo; si no paga, la obra se libera."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller)
        self.winner = UserFactory()
        self.other = UserFactory()
        now = timezone.now()
        self.artwork = ArtworkFactory(artist=self.profile, status=Artwork.Status.EN_SUBASTA)
        self.auction = Auction.objects.create(
            artwork=self.artwork,
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now - timedelta(hours=1),
            ends_at=now + timedelta(hours=1),
            status=Auction.Status.ACTIVA,
        )

    def _win(self, amount="180000.00"):
        AuctionService.place_bid(auction=self.auction, bidder=self.winner, amount=Decimal(amount))
        AuctionService.close_auction(auction=self.auction, actor=self.seller)
        self.auction.refresh_from_db()
        self.artwork.refresh_from_db()
        return self.auction.payment_order

    # --- creación de la orden -------------------------------------------------

    def test_closing_with_winner_creates_pending_auction_order(self):
        before = timezone.now()
        order = self._win()
        self.assertIsNotNone(order)
        self.assertEqual(order.buyer, self.winner)
        self.assertEqual(order.order_type, Order.Type.SUBASTA)
        self.assertEqual(order.status, Order.Status.PENDIENTE)
        self.assertEqual(order.total_amount, Decimal("180000.00"))
        self.assertEqual([i.artwork_id for i in order.items.all()], [self.artwork.id])
        self.assertGreaterEqual(order.payment_due_at, before + timedelta(hours=48))
        self.assertEqual(self.artwork.status, Artwork.Status.INACTIVA)

    def test_winner_is_notified_with_order_and_deadline(self):
        order = self._win()
        log = NotificationLog.objects.get(notification_type="AUCTION_CLOSED")
        self.assertEqual(log.payload["order_id"], str(order.id))
        self.assertEqual(log.payload["winner_email"], self.winner.email)
        self.assertIsNotNone(log.payload["payment_due_at"])

    def test_closing_without_bids_creates_no_order(self):
        AuctionService.close_auction(auction=self.auction, actor=self.seller)
        self.auction.refresh_from_db()
        self.artwork.refresh_from_db()
        self.assertIsNone(self.auction.payment_order)
        self.assertFalse(Order.objects.exists())
        self.assertEqual(self.artwork.status, Artwork.Status.DISPONIBLE)

    def test_automatic_close_also_creates_order(self):
        AuctionService.place_bid(auction=self.auction, bidder=self.winner, amount=Decimal("150000.00"))
        Auction.objects.filter(id=self.auction.id).update(ends_at=timezone.now() - timedelta(minutes=1))
        close_expired_auctions()
        self.auction.refresh_from_db()
        self.assertEqual(self.auction.payment_order.buyer, self.winner)

    # --- pago -----------------------------------------------------------------

    def test_winner_can_initiate_payment(self):
        order = self._win()
        self.client.force_authenticate(user=self.winner)
        r = self.client.post("/api/v1/payments/initiate/", {"order_id": str(order.id)}, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["amount_in_cents"], 18000000)
        self.assertEqual(r.data["reference"], str(order.id))

    def test_other_user_cannot_pay_winner_order(self):
        order = self._win()
        self.client.force_authenticate(user=self.other)
        r = self.client.post("/api/v1/payments/initiate/", {"order_id": str(order.id)}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_cannot_pay_after_deadline(self):
        order = self._win()
        Order.objects.filter(id=order.id).update(payment_due_at=timezone.now() - timedelta(minutes=1))
        self.client.force_authenticate(user=self.winner)
        r = self.client.post("/api/v1/payments/initiate/", {"order_id": str(order.id)}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("venció", r.data["detail"])

    # --- vencimiento ------------------------------------------------------------

    def test_unpaid_order_expires_and_artwork_is_released(self):
        order = self._win()
        Order.objects.filter(id=order.id).update(payment_due_at=timezone.now() - timedelta(minutes=1))
        expire_unpaid_auction_orders()
        order.refresh_from_db()
        self.artwork.refresh_from_db()
        self.assertEqual(order.status, Order.Status.CANCELADO)
        self.assertEqual(self.artwork.status, Artwork.Status.DISPONIBLE)
        log = NotificationLog.objects.get(notification_type="AUCTION_PAYMENT_EXPIRED")
        self.assertEqual(log.payload["buyer_email"], self.winner.email)

    def test_order_within_deadline_is_not_expired(self):
        order = self._win()
        self.assertEqual(AuctionService.expire_unpaid_orders(), 0)
        order.refresh_from_db()
        self.assertEqual(order.status, Order.Status.PENDIENTE)

    def test_paid_order_is_never_expired(self):
        order = self._win()
        Order.objects.filter(id=order.id).update(
            status=Order.Status.PAGADO, payment_due_at=timezone.now() - timedelta(minutes=1)
        )
        self.assertEqual(AuctionService.expire_unpaid_orders(), 0)
        order.refresh_from_db()
        self.assertEqual(order.status, Order.Status.PAGADO)

    def test_direct_purchase_orders_are_not_affected(self):
        Order.objects.create(
            buyer=self.other,
            total_amount=Decimal("50000.00"),
            order_type=Order.Type.COMPRA_DIRECTA,
        )
        self.assertEqual(AuctionService.expire_unpaid_orders(), 0)

    # --- API ----------------------------------------------------------------------

    def test_only_winner_sees_payment_order_id(self):
        order = self._win()
        url = f"/api/v1/auctions/{self.auction.id}/"
        self.client.force_authenticate(user=self.winner)
        self.assertEqual(self.client.get(url).data["payment_order_id"], str(order.id))
        self.client.force_authenticate(user=self.other)
        self.assertIsNone(self.client.get(url).data["payment_order_id"])
        self.client.force_authenticate(user=None)
        self.assertIsNone(self.client.get(url).data["payment_order_id"])

    def test_winner_order_appears_in_orders_with_deadline(self):
        order = self._win()
        self.client.force_authenticate(user=self.winner)
        r = self.client.get("/api/v1/marketplace/orders/")
        data = r.data["results"] if isinstance(r.data, dict) else r.data
        (listed,) = (o for o in data if o["id"] == str(order.id))
        self.assertEqual(listed["order_type"], "SUBASTA")
        self.assertIsNotNone(listed["payment_due_at"])
