from datetime import timedelta
from decimal import Decimal
from unittest.mock import patch

from celery.exceptions import Retry
from django.core import mail
from django.db import transaction
from django.test import TestCase, override_settings
from django.utils import timezone

from apps.marketplace.models import Order
from apps.notifications.models import NotificationLog
from apps.notifications.tasks import deliver_notification
from services.email_service import EmailResult
from services.notification_service import NotificationService
from tests.factories import UserFactory

FRONTEND = "https://narinocultura.test"


@override_settings(FRONTEND_URL=FRONTEND)
class NotificationEmailTests(TestCase):
    """HU-B08 (RF32): cada notificación de negocio se envía por correo desde Django, sin n8n."""

    def setUp(self):
        self.user = UserFactory(first_name="Ana", last_name="Pérez")

    def deliver(self, notification_type, payload, user=None):
        with self.captureOnCommitCallbacks(execute=True):
            log = NotificationService.send(notification_type, payload, user=user)
        log.refresh_from_db()
        return log

    def test_auction_opened_goes_to_seller(self):
        log = self.deliver("AUCTION_OPENED", {
            "auction_id": "abc", "artwork_title": "Carnaval", "seller_email": "artista@test.com",
            "seller_name": "Artista Uno", "ends_at": "2030-12-15T20:00:00-05:00",
        })
        self.assertEqual(log.status, NotificationLog.Status.ENVIADO)
        (email,) = mail.outbox
        self.assertEqual(email.to, ["artista@test.com"])
        self.assertIn("aprobada", email.subject)
        html = email.alternatives[0][0]
        self.assertIn("Hola Artista,", html)
        self.assertIn("15 de diciembre de 2030", html)
        self.assertIn(f"{FRONTEND}/auctions/abc", html)

    def test_auction_rejected_goes_to_seller(self):
        self.deliver("AUCTION_REJECTED", {"artwork_title": "Carnaval", "seller_email": "artista@test.com"})
        self.assertEqual(mail.outbox[0].to, ["artista@test.com"])
        self.assertIn("no aprobada", mail.outbox[0].subject)

    def test_auction_won_includes_price_deadline_and_payment_link(self):
        self.deliver("AUCTION_CLOSED", {
            "artwork_title": "Carnaval", "winner_email": "ganador@test.com", "winner_name": "Ana",
            "final_price": "180000.00", "payment_due_at": "2030-12-17T20:00:00-05:00",
        })
        (email,) = mail.outbox
        self.assertEqual(email.to, ["ganador@test.com"])
        html = email.alternatives[0][0]
        self.assertIn("$180.000 COP", html)
        self.assertIn("17 de diciembre de 2030", html)
        self.assertIn("Pagar mi obra", html)
        self.assertIn(f"{FRONTEND}/orders", html)

    def test_auction_closed_without_winner_sends_no_email(self):
        log = self.deliver("AUCTION_CLOSED", {"artwork_title": "Carnaval", "winner_email": ""})
        self.assertEqual(log.status, NotificationLog.Status.SIN_CORREO)
        self.assertEqual(mail.outbox, [])

    def test_payment_expired_goes_to_buyer(self):
        self.deliver("AUCTION_PAYMENT_EXPIRED", {"buyer_email": self.user.email, "total_amount": "50000.00"}, self.user)
        self.assertEqual(mail.outbox[0].to, [self.user.email])
        self.assertIn("$50.000 COP", mail.outbox[0].alternatives[0][0])

    def test_approved_payment_goes_to_order_buyer(self):
        order = Order.objects.create(buyer=self.user, total_amount=Decimal("75000.00"), status=Order.Status.PAGADO)
        self.deliver("PAYMENT_WEBHOOK", {"order_id": str(order.id), "status": "APROBADO"})
        (email,) = mail.outbox
        self.assertEqual(email.to, [self.user.email])
        self.assertIn("Pago confirmado", email.subject)
        self.assertIn("$75.000 COP", email.alternatives[0][0])

    def test_rejected_payment_sends_no_email(self):
        order = Order.objects.create(buyer=self.user, total_amount=Decimal("75000.00"))
        log = self.deliver("PAYMENT_WEBHOOK", {"order_id": str(order.id), "status": "RECHAZADO"})
        self.assertEqual(log.status, NotificationLog.Status.SIN_CORREO)
        self.assertEqual(mail.outbox, [])

    def test_event_registration_goes_to_user(self):
        self.deliver("EVENT_REGISTRATION", {
            "event_id": "ev1", "event_title": "Noche andina", "event_date": "2030-11-20T19:00:00-05:00",
            "event_location": "Teatro Imperial", "user_email": "ana@test.com", "user_name": "Ana",
        })
        html = mail.outbox[0].alternatives[0][0]
        self.assertEqual(mail.outbox[0].to, ["ana@test.com"])
        self.assertIn("Teatro Imperial", html)
        self.assertIn("20 de noviembre de 2030", html)
        self.assertIn(f"{FRONTEND}/events/ev1", html)

    def test_types_without_email_are_only_logged(self):
        for notification_type in ("AUCTION_BID", "AUCTION_PENDING", "ORDER_CREATED", "EVENT_PUBLISHED"):
            log = self.deliver(notification_type, {"auction_id": "x"}, self.user)
            self.assertEqual(log.status, NotificationLog.Status.SIN_CORREO, notification_type)
        self.assertEqual(mail.outbox, [])

    def test_plain_text_version_is_included(self):
        self.deliver("AUCTION_REJECTED", {"artwork_title": "Carnaval", "seller_email": "artista@test.com"})
        self.assertIn("Carnaval", mail.outbox[0].body)
        self.assertNotIn("<p>", mail.outbox[0].body)


class NotificationDeliveryTests(TestCase):
    """Entrega asíncrona: después del commit, con reintentos y sin romper la operación del usuario."""

    PAYLOAD = {"artwork_title": "Carnaval", "seller_email": "artista@test.com"}

    def _pending_log(self):
        # Registro sin ejecutar el on_commit: la entrega se dispara a mano con el intento deseado
        return NotificationService.send("AUCTION_REJECTED", self.PAYLOAD)

    def test_nothing_is_sent_inside_the_transaction(self):
        with self.captureOnCommitCallbacks(execute=False) as callbacks:
            with transaction.atomic():
                log = NotificationService.send("AUCTION_REJECTED", self.PAYLOAD)
            self.assertEqual(mail.outbox, [])
        self.assertEqual(len(callbacks), 1)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)

    def test_rolled_back_operation_sends_nothing(self):
        with self.captureOnCommitCallbacks(execute=True):
            try:
                with transaction.atomic():
                    NotificationService.send("AUCTION_REJECTED", self.PAYLOAD)
                    raise RuntimeError("la operación falló")
            except RuntimeError:
                pass
        self.assertEqual(mail.outbox, [])
        self.assertFalse(NotificationLog.objects.exists())

    @patch("services.notification_service.EmailService.send_template", return_value=EmailResult(ok=False, error_message="Resend 503"))
    def test_failed_send_schedules_retry_with_backoff(self, _send):
        log = self._pending_log()
        for attempt, countdown in ((0, 30), (1, 60), (2, 120)):
            with self.assertRaises(Retry) as ctx:
                deliver_notification.apply(args=[str(log.id)], retries=attempt, throw=True)
            self.assertEqual(ctx.exception.when, countdown)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)

    @patch("services.notification_service.EmailService.send_template", return_value=EmailResult(ok=False, error_message="Resend 503"))
    def test_gives_up_after_last_retry(self, _send):
        log = self._pending_log()
        deliver_notification.apply(args=[str(log.id)], retries=deliver_notification.max_retries, throw=True)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.FALLIDO)

    def test_retry_that_succeeds_marks_sent(self):
        log = self._pending_log()
        deliver_notification.apply(args=[str(log.id)], retries=2, throw=True)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.ENVIADO)
        self.assertEqual(len(mail.outbox), 1)

    def test_already_sent_log_is_not_sent_twice(self):
        with self.captureOnCommitCallbacks(execute=True):
            log = NotificationService.send("AUCTION_REJECTED", self.PAYLOAD)
        NotificationService.deliver(str(log.id))
        self.assertEqual(len(mail.outbox), 1)

    def test_enqueue_failure_does_not_break_the_caller(self):
        with patch("apps.notifications.tasks.deliver_notification.delay", side_effect=ConnectionError("redis caído")):
            with self.captureOnCommitCallbacks(execute=True):
                log = NotificationService.send("AUCTION_REJECTED", self.PAYLOAD)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)

    def test_bid_does_not_wait_for_email(self):
        from apps.auctions.models import Auction
        from services.auction_service import AuctionService
        from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory

        seller = ArtistUserFactory()
        now = timezone.now()
        auction = Auction.objects.create(
            artwork=ArtworkFactory(artist=ArtistProfileFactory(user=seller), status="EN_SUBASTA"),
            seller=seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now - timedelta(hours=1),
            ends_at=now + timedelta(hours=1),
            status=Auction.Status.ACTIVA,
        )
        with patch("services.notification_service.EmailService.send_template") as send, self.captureOnCommitCallbacks():
            AuctionService.place_bid(auction=auction, bidder=UserFactory(), amount=Decimal("110000.00"))
            send.assert_not_called()
        log = NotificationLog.objects.get(notification_type="AUCTION_BID")
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)
