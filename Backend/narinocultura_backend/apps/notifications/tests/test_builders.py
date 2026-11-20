"""Constructores de correos y de avisos de bandeja ante datos incompletos o inesperados."""
import uuid
from datetime import timedelta
from decimal import Decimal
from types import SimpleNamespace

from django.test import SimpleTestCase, TestCase
from django.utils import timezone

from apps.auctions.models import Auction
from apps.marketplace.models import Order
from apps.notifications.models import Notification, NotificationLog
from services.notification_emails import build_notification_email, format_date, format_price
from services.notification_inbox import build_inbox_items
from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, EventFactory, UserFactory


class FormattingTests(SimpleTestCase):
    def test_format_price(self):
        self.assertEqual(format_price("180000"), "$180.000 COP")
        self.assertEqual(format_price(Decimal("1234567.4")), "$1.234.567 COP")

    def test_format_price_with_invalid_value_is_empty(self):
        for value in (None, "abc", ""):
            with self.subTest(value=value):
                self.assertEqual(format_price(value), "")

    def test_format_date_without_value_is_empty(self):
        self.assertEqual(format_date(None), "")
        self.assertEqual(format_date(""), "")
        self.assertEqual(format_date("no es fecha"), "")


class NotificationEmailEdgeCaseTests(TestCase):
    def log(self, notification_type, payload, user=None):
        return SimpleNamespace(notification_type=notification_type, payload=payload, user=user)

    def test_unknown_type_has_no_email(self):
        self.assertIsNone(build_notification_email(self.log("AUCTION_BID", {"amount": 1})))

    def test_email_without_recipient_is_skipped(self):
        self.assertIsNone(build_notification_email(self.log("AUCTION_REJECTED", None)))

    def test_approved_payment_for_missing_order_has_no_email(self):
        log = self.log("PAYMENT_WEBHOOK", {"status": "APROBADO", "order_id": str(uuid.uuid4())})
        self.assertIsNone(build_notification_email(log))

    def test_payment_expired_without_user_has_no_name(self):
        email = build_notification_email(
            self.log("AUCTION_PAYMENT_EXPIRED", {"buyer_email": "b@test.com", "total_amount": "50000"})
        )
        self.assertEqual(email.to, "b@test.com")
        self.assertEqual(email.context["name"], "")
        self.assertEqual(email.context["details"], [("Valor de la orden", "$50.000 COP")])


class InboxEdgeCaseTests(TestCase):
    """Avisos de bandeja para casos que los flujos completos no recorren."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        self.artwork = ArtworkFactory(artist=ArtistProfileFactory(user=self.seller), title="Carnaval")
        now = timezone.now()
        self.auction = Auction.objects.create(
            artwork=self.artwork, seller=self.seller, base_price=Decimal("1000.00"),
            current_price=Decimal("1000.00"), starts_at=now, ends_at=now + timedelta(days=1),
        )

    def test_unknown_type_produces_nothing(self):
        self.assertEqual(build_inbox_items("ORDER_CREATED", {"order_id": "1"}), [])

    def test_invalid_or_missing_ids_produce_nothing(self):
        for notification_type in ("AUCTION_OPENED", "AUCTION_REJECTED", "AUCTION_BID", "AUCTION_CLOSED",
                                  "AUCTION_PAYMENT_EXPIRED", "EVENT_REGISTRATION", "EVENT_PUBLISHED"):
            for payload in (None, {"auction_id": "no-uuid", "order_id": "no-uuid", "event_id": "no-uuid"}):
                with self.subTest(notification_type=notification_type, payload=payload):
                    self.assertEqual(build_inbox_items(notification_type, payload), [])

    def test_auction_rejected_notifies_seller(self):
        [item] = build_inbox_items("AUCTION_REJECTED", {"auction_id": str(self.auction.id)})
        self.assertEqual(item.recipient_id, self.seller.id)
        self.assertEqual(item.title, "Subasta no aprobada")
        self.assertIn("«Carnaval» no fue aprobada", item.body)
        self.assertEqual(item.data, {"auction_id": str(self.auction.id), "url": f"/auctions/{self.auction.id}"})

    def test_auction_opened_without_end_date_has_short_body(self):
        [item] = build_inbox_items("AUCTION_OPENED", {"auction_id": str(self.auction.id)})
        self.assertEqual(item.body, "La subasta de «Carnaval» ya está activa.")

    def test_payment_expired_notifies_buyer(self):
        buyer = UserFactory()
        order = Order.objects.create(buyer=buyer, total_amount=Decimal("50000.00"))
        [item] = build_inbox_items("AUCTION_PAYMENT_EXPIRED", {"order_id": str(order.id)})
        self.assertEqual(item.recipient_id, buyer.id)
        self.assertEqual(item.title, "Venció el plazo de pago")
        self.assertEqual(item.data, {"order_id": str(order.id), "url": "/orders"})

    def test_approved_payment_for_missing_order_produces_nothing(self):
        payload = {"status": "APROBADO", "order_id": str(uuid.uuid4())}
        self.assertEqual(build_inbox_items("PAYMENT_WEBHOOK", payload), [])

    def test_event_registration_for_unknown_email_produces_nothing(self):
        event = EventFactory()
        payload = {"event_id": str(event.id), "user_email": "nadie@test.com"}
        self.assertEqual(build_inbox_items("EVENT_REGISTRATION", payload), [])


class NotificationModelStrTests(TestCase):
    def test_str_representations(self):
        user = UserFactory()
        log = NotificationLog.objects.create(user=user, notification_type="AUCTION_BID", status="ENVIADO")
        notification = Notification.objects.create(recipient=user, notification_type="X", title="Nueva puja")
        self.assertEqual(str(log), "AUCTION_BID - ENVIADO")
        self.assertEqual(str(notification), f"{user.id} - Nueva puja")
