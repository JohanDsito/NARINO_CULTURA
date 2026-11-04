from decimal import Decimal
from unittest.mock import MagicMock, patch

import requests
from celery.exceptions import Retry
from django.db import transaction
from django.test import TestCase, override_settings

from apps.notifications.models import NotificationLog
from apps.notifications.tasks import deliver_notification
from services.notification_service import NotificationService
from tests.factories import UserFactory

N8N = "https://n8n.test/webhook/narinocultura"


def response(status_code):
    return MagicMock(status_code=status_code)


@override_settings(N8N_WEBHOOK_URL=N8N)
@patch("services.notification_service.requests.post")
class NotificationDeliveryTests(TestCase):
    """HU-B08 (RF32): las notificaciones llegan a n8n de forma asíncrona y sin bloquear transacciones."""

    def setUp(self):
        self.user = UserFactory(first_name="Ana", last_name="Pérez")

    def _send(self, **kwargs):
        with self.captureOnCommitCallbacks(execute=True):
            return NotificationService.send("AUCTION_BID", {"amount": "120000.00"}, user=self.user, **kwargs)

    def test_delivers_to_n8n_after_commit_with_user_data(self, post):
        post.return_value = response(200)
        log = self._send()
        post.assert_called_once()
        self.assertEqual(post.call_args.args[0], N8N)
        body = post.call_args.kwargs["json"]
        self.assertEqual(body["type"], "AUCTION_BID")
        self.assertEqual(body["payload"], {"amount": "120000.00"})
        self.assertEqual(body["user"]["email"], self.user.email)
        self.assertEqual(body["user"]["first_name"], "Ana")
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.ENVIADO)

    def test_no_http_call_inside_the_transaction(self, post):
        post.return_value = response(200)
        with self.captureOnCommitCallbacks(execute=False) as callbacks:
            with transaction.atomic():
                log = NotificationService.send("PAYMENT_WEBHOOK", {"order_id": "1"})
                post.assert_not_called()
        self.assertEqual(len(callbacks), 1)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)

    def test_rolled_back_operation_sends_nothing(self, post):
        with self.captureOnCommitCallbacks(execute=True):
            try:
                with transaction.atomic():
                    NotificationService.send("AUCTION_BID", {"amount": "1"})
                    raise RuntimeError("la puja falló")
            except RuntimeError:
                pass
        post.assert_not_called()
        self.assertFalse(NotificationLog.objects.exists())

    @override_settings(N8N_WEBHOOK_URL="")
    def test_without_webhook_url_marks_failed_without_http(self, post):
        log = self._send()
        post.assert_not_called()
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.FALLIDO)

    def _pending_log(self):
        # Registro sin ejecutar el on_commit: la entrega se dispara a mano con el intento deseado
        return NotificationService.send("AUCTION_BID", {"amount": "1"}, user=self.user)

    def test_temporary_error_schedules_retry_with_backoff(self, post):
        post.side_effect = requests.ConnectionError("caído")
        log = self._pending_log()
        for attempt, countdown in ((0, 30), (1, 60), (2, 120)):
            with self.assertRaises(Retry) as ctx:
                deliver_notification.apply(args=[str(log.id)], retries=attempt, throw=True)
            self.assertEqual(ctx.exception.when, countdown)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)

    def test_server_error_is_retried(self, post):
        post.return_value = response(503)
        log = self._pending_log()
        with self.assertRaises(Retry):
            deliver_notification.apply(args=[str(log.id)], throw=True)

    def test_retry_that_succeeds_marks_sent(self, post):
        post.return_value = response(200)
        log = self._pending_log()
        deliver_notification.apply(args=[str(log.id)], retries=2, throw=True)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.ENVIADO)

    def test_gives_up_after_last_retry(self, post):
        post.side_effect = requests.Timeout("lento")
        log = self._pending_log()
        deliver_notification.apply(args=[str(log.id)], retries=deliver_notification.max_retries, throw=True)
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.FALLIDO)

    def test_enqueue_failure_does_not_break_the_caller(self, post):
        with patch("apps.notifications.tasks.deliver_notification.delay", side_effect=ConnectionError("redis caído")):
            log = self._send()
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)

    def test_client_error_is_not_retried(self, post):
        post.return_value = response(400)
        log = self._send()
        post.assert_called_once()
        log.refresh_from_db()
        self.assertEqual(log.status, NotificationLog.Status.FALLIDO)

    def test_already_delivered_log_is_not_sent_twice(self, post):
        post.return_value = response(200)
        log = self._send()
        NotificationService.deliver(str(log.id))
        post.assert_called_once()

    def test_anonymous_notification_has_no_user_block(self, post):
        post.return_value = response(200)
        with self.captureOnCommitCallbacks(execute=True):
            NotificationService.send("PAYMENT_WEBHOOK", {"order_id": "1"})
        self.assertNotIn("user", post.call_args.kwargs["json"])


@override_settings(N8N_WEBHOOK_URL=N8N)
class BidDoesNotWaitForN8nTests(TestCase):
    def test_bid_transaction_does_not_call_n8n(self):
        from datetime import timedelta

        from django.utils import timezone

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
        with patch("services.notification_service.requests.post") as post, self.captureOnCommitCallbacks() as callbacks:
            AuctionService.place_bid(auction=auction, bidder=UserFactory(), amount=Decimal("110000.00"))
            post.assert_not_called()
        self.assertTrue(callbacks)
        log = NotificationLog.objects.get(notification_type="AUCTION_BID")
        self.assertEqual(log.status, NotificationLog.Status.PENDIENTE)
