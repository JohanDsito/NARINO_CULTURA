from datetime import timedelta
from decimal import Decimal
from unittest.mock import patch

from django.contrib.auth.models import AnonymousUser
from django.test import TestCase
from django.utils import timezone

from apps.artworks.models import Artwork
from apps.auctions.models import Auction, Bid
from apps.marketplace.models import Order, OrderItem
from apps.notifications.models import NotificationLog
from services.auction_service import AuctionService
from tests.factories import AdminUserFactory, ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory


class AuctionRulesTestCase(TestCase):
    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller)
        self.admin = AdminUserFactory()
        self.buyer = UserFactory()

    def _auction(self, status=Auction.Status.ACTIVA, *, starts=-1, ends=24, artwork_status=Artwork.Status.EN_SUBASTA):
        now = timezone.now()
        return Auction.objects.create(
            artwork=ArtworkFactory(artist=self.profile, status=artwork_status),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now + timedelta(hours=starts),
            ends_at=now + timedelta(hours=ends),
            status=status,
        )

    def _create(self, *, seller=None, artwork=None, starts=-1, ends=24):
        now = timezone.now()
        return AuctionService.create_auction(
            seller=seller or self.seller,
            artwork=artwork or ArtworkFactory(artist=self.profile),
            base_price=Decimal("100000.00"),
            starts_at=now + timedelta(hours=starts),
            ends_at=now + timedelta(hours=ends),
        )


class CreateAuctionRulesTests(AuctionRulesTestCase):
    """HU-B01: solo el artista dueño de una obra disponible puede subastarla."""

    def test_buyer_cannot_create_auction(self):
        with self.assertRaisesMessage(ValueError, "ARTISTA"):
            self._create(seller=self.buyer)
        self.assertFalse(Auction.objects.exists())

    def test_artist_cannot_auction_someone_elses_artwork(self):
        other_artist = ArtistUserFactory()
        with self.assertRaisesMessage(ValueError, "propias obras"):
            self._create(seller=other_artist)
        self.assertFalse(Auction.objects.exists())

    def test_artwork_must_be_available(self):
        sold = ArtworkFactory(artist=self.profile, status=Artwork.Status.VENDIDA)
        with self.assertRaisesMessage(ValueError, "DISPONIBLE"):
            self._create(artwork=sold)

    def test_end_must_be_after_start(self):
        with self.assertRaisesMessage(ValueError, "fecha fin"):
            self._create(starts=5, ends=5)

    def test_creation_notifies_pending_review(self):
        auction = self._create()
        log = NotificationLog.objects.get(notification_type="AUCTION_PENDING")
        self.assertEqual(log.payload["auction_id"], str(auction.id))
        self.assertEqual(log.payload["seller_email"], self.seller.email)


class ModerationRulesTests(AuctionRulesTestCase):
    """HU-B02: la aprobación y el rechazo son exclusivos del administrador y solo sobre PENDIENTE."""

    def test_cannot_approve_an_active_auction_twice(self):
        auction = self._auction(Auction.Status.ACTIVA)
        with self.assertRaisesMessage(ValueError, "PENDIENTE"):
            AuctionService.approve_auction(auction=auction, actor=self.admin)

    def test_only_admin_can_reject(self):
        auction = self._auction(Auction.Status.PENDIENTE, artwork_status=Artwork.Status.DISPONIBLE)
        with self.assertRaisesMessage(ValueError, "administrador"):
            AuctionService.reject_auction(auction=auction, actor=self.seller)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.PENDIENTE)

    def test_cannot_reject_an_active_auction(self):
        auction = self._auction(Auction.Status.ACTIVA)
        with self.assertRaisesMessage(ValueError, "PENDIENTE"):
            AuctionService.reject_auction(auction=auction, actor=self.admin)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)


class BidRulesTests(AuctionRulesTestCase):
    """HU-B06: reglas de la puja que no dependen de la concurrencia."""

    def test_anonymous_cannot_bid(self):
        auction = self._auction()
        with self.assertRaisesMessage(ValueError, "Autenticación"):
            AuctionService.place_bid(auction=auction, bidder=AnonymousUser(), amount=Decimal("200000.00"))
        self.assertFalse(Bid.objects.exists())

    def test_cannot_bid_before_auction_starts(self):
        auction = self._auction(starts=2, ends=24)
        with self.assertRaisesMessage(ValueError, "aún no ha iniciado"):
            AuctionService.place_bid(auction=auction, bidder=self.buyer, amount=Decimal("200000.00"))
        auction.refresh_from_db()
        self.assertEqual(auction.current_price, Decimal("100000.00"))
        self.assertIsNone(auction.highest_bidder)

    def test_bid_notifies_previous_highest_bidder(self):
        auction = self._auction()
        first = UserFactory()
        AuctionService.place_bid(auction=auction, bidder=first, amount=Decimal("150000.00"))
        AuctionService.place_bid(auction=auction, bidder=self.buyer, amount=Decimal("160000.00"))
        logs = NotificationLog.objects.filter(notification_type="AUCTION_BID").order_by("created_at")
        self.assertIsNone(logs[0].payload["previous_bidder_id"])
        self.assertEqual(logs[1].payload["previous_bidder_id"], str(first.id))


class CloseRulesTests(AuctionRulesTestCase):
    """HU-B04: cierre manual por el vendedor o el administrador, una sola vez."""

    def test_cannot_close_twice(self):
        auction = self._auction()
        AuctionService.close_auction(auction=auction, actor=self.seller)
        with self.assertRaisesMessage(ValueError, "ya fue cerrada"):
            AuctionService.close_auction(auction=auction, actor=self.seller)

    def test_cannot_close_pending_auction(self):
        auction = self._auction(Auction.Status.PENDIENTE, artwork_status=Artwork.Status.DISPONIBLE)
        with self.assertRaises(ValueError):
            AuctionService.close_auction(auction=auction, actor=self.admin)

    def test_other_user_cannot_close(self):
        auction = self._auction()
        AuctionService.place_bid(auction=auction, bidder=self.buyer, amount=Decimal("150000.00"))
        with self.assertRaisesMessage(ValueError, "permisos"):
            AuctionService.close_auction(auction=auction, actor=self.buyer)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)
        self.assertIsNone(auction.winner)

    def test_admin_can_close_foreign_auction(self):
        auction = self._auction()
        AuctionService.place_bid(auction=auction, bidder=self.buyer, amount=Decimal("150000.00"))
        AuctionService.close_auction(auction=auction, actor=self.admin)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.CERRADA)
        self.assertEqual(auction.winner, self.buyer)

    def test_automatic_close_ignores_auction_still_running(self):
        auction = self._auction(ends=2)
        AuctionService._close_if_ended(auction_id=auction.id)
        auction.refresh_from_db()
        self.assertEqual(auction.status, Auction.Status.ACTIVA)

    def test_automatic_close_ignores_unknown_or_closed_auction(self):
        closed = self._auction(Auction.Status.CERRADA, ends=-1)
        AuctionService._close_if_ended(auction_id=closed.id)
        closed.refresh_from_db()
        self.assertEqual(closed.status, Auction.Status.CERRADA)
        self.assertFalse(NotificationLog.objects.filter(notification_type="AUCTION_CLOSED").exists())


class ExpireUnpaidOrdersRulesTests(AuctionRulesTestCase):
    """HU-B04 (RF21): al vencer el plazo solo se liberan las obras que seguían reservadas."""

    def _expired_order(self, artwork_status):
        artwork = ArtworkFactory(artist=self.profile, status=artwork_status)
        order = Order.objects.create(
            buyer=self.buyer,
            total_amount=Decimal("150000.00"),
            order_type=Order.Type.SUBASTA,
            payment_due_at=timezone.now() - timedelta(minutes=5),
        )
        OrderItem.objects.create(order=order, artwork=artwork, price=Decimal("150000.00"))
        return order, artwork

    def test_artwork_not_reserved_keeps_its_status(self):
        # La obra ya no estaba reservada (p. ej. un administrador la retiró): no se reactiva
        order, artwork = self._expired_order(Artwork.Status.VENDIDA)
        self.assertEqual(AuctionService.expire_unpaid_orders(), 1)
        order.refresh_from_db()
        artwork.refresh_from_db()
        self.assertEqual(order.status, Order.Status.CANCELADO)
        self.assertEqual(artwork.status, Artwork.Status.VENDIDA)

    def test_order_paid_meanwhile_is_skipped(self):
        """Si el webhook confirma el pago entre la consulta y el bloqueo, la orden no se cancela."""
        order, artwork = self._expired_order(Artwork.Status.INACTIVA)
        original_lock = Order.objects.select_for_update

        def pay_then_lock(*args, **kwargs):
            # Justo antes de bloquear la fila llega el webhook con el pago aprobado
            Order.objects.filter(id=order.id).update(status=Order.Status.PAGADO)
            return original_lock(*args, **kwargs)

        with patch.object(Order.objects, "select_for_update", side_effect=pay_then_lock):
            expired = AuctionService.expire_unpaid_orders()
        self.assertEqual(expired, 0)
        order.refresh_from_db()
        artwork.refresh_from_db()
        self.assertEqual(order.status, Order.Status.PAGADO)
        self.assertEqual(artwork.status, Artwork.Status.INACTIVA)
