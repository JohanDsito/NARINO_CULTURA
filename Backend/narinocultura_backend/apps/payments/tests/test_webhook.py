from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.artworks.models import Artwork
from apps.marketplace.models import Order, OrderItem
from apps.notifications.models import NotificationLog
from apps.payments.models import Transaction
from services.payment_service import PaymentService
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory
from tests.wompi import signed_wompi_event

URL = "/api/v1/payments/wompi-webhook/"


class WompiWebhookTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.buyer = UserFactory(role="COMPRADOR")
        self.profile = ArtistProfileFactory()
        # La obra queda INACTIVA (reservada) al hacer checkout
        self.artwork = ArtworkFactory(artist=self.profile, status=Artwork.Status.INACTIVA)
        self.order = Order.objects.create(buyer=self.buyer, total_amount="200000.00")
        OrderItem.objects.create(order=self.order, artwork=self.artwork, price="200000.00")
        Transaction.objects.create(order=self.order, amount="200000.00", currency="COP", status="PENDIENTE")

    def _transaction(self, status="APPROVED", **overrides):
        tx = {
            "id": "wompi-test-001",
            "status": status,
            "reference": str(self.order.id),
            "amount_in_cents": 20000000,
            "currency": "COP",
            "payment_method_type": "CARD",
        }
        tx.update(overrides)
        return tx

    def _post(self, payload, **headers):
        return self.client.post(URL, payload, format="json", **headers)

    def _refresh(self):
        self.order.refresh_from_db()
        self.artwork.refresh_from_db()

    # --- firma ---------------------------------------------------------------

    def test_approved_event_marks_order_paid_and_artwork_sold(self):
        r = self._post(signed_wompi_event(self._transaction("APPROVED")))
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PAGADO)
        self.assertEqual(self.artwork.status, Artwork.Status.VENDIDA)
        tx = Transaction.objects.get(order=self.order)
        self.assertEqual(tx.status, Transaction.Status.APROBADO)
        self.assertEqual(tx.wompi_transaction_id, "wompi-test-001")

    def test_checksum_in_header_is_accepted(self):
        payload = signed_wompi_event(self._transaction("APPROVED"))
        checksum = payload["signature"].pop("checksum")
        r = self._post(payload, HTTP_X_EVENT_CHECKSUM=checksum)
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PAGADO)

    def test_lowercase_checksum_is_accepted(self):
        payload = signed_wompi_event(self._transaction("APPROVED"))
        payload["signature"]["checksum"] = payload["signature"]["checksum"].lower()
        self.assertEqual(self._post(payload).status_code, 200)

    def test_invalid_checksum_returns_401(self):
        payload = signed_wompi_event(self._transaction("APPROVED"))
        payload["signature"]["checksum"] = "0" * 64
        r = self._post(payload)
        self.assertEqual(r.status_code, 401)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    def test_event_signed_with_another_secret_returns_401(self):
        r = self._post(signed_wompi_event(self._transaction("APPROVED"), secret="otro_secreto"))
        self.assertEqual(r.status_code, 401)

    def test_tampered_status_after_signing_returns_401(self):
        payload = signed_wompi_event(self._transaction("DECLINED"))
        payload["data"]["transaction"]["status"] = "APPROVED"
        self.assertEqual(self._post(payload).status_code, 401)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    def test_unsigned_payload_returns_401(self):
        r = self._post({"event": "transaction.updated", "data": {"transaction": self._transaction("APPROVED")}})
        self.assertEqual(r.status_code, 401)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    @override_settings(WOMPI_EVENTS_SECRET="")
    def test_missing_events_secret_rejects_every_event(self):
        payload = signed_wompi_event(self._transaction("APPROVED"), secret="")
        self.assertEqual(self._post(payload).status_code, 401)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    def test_signature_string_matches_wompi_documentation(self):
        """Cadena de ejemplo de docs.wompi.co/docs/colombia/eventos."""
        payload = {
            "data": {"transaction": {"id": "1234-1610641025-49201", "status": "APPROVED", "amount_in_cents": 4490000}},
            "signature": {"properties": ["transaction.id", "transaction.status", "transaction.amount_in_cents"]},
            "timestamp": 1530291411,
        }
        self.assertEqual(
            PaymentService.event_signature_string(payload=payload, secret="prod_events_OcHnIzeBl5socpwByQ4hA52Em3USQ93Z"),
            "1234-1610641025-49201APPROVED44900001530291411prod_events_OcHnIzeBl5socpwByQ4hA52Em3USQ93Z",
        )

    # --- validaciones de negocio ----------------------------------------------

    def test_amount_mismatch_returns_400_and_keeps_order_pending(self):
        r = self._post(signed_wompi_event(self._transaction("APPROVED", amount_in_cents=100)))
        self.assertEqual(r.status_code, 400)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)
        self.assertEqual(self.artwork.status, Artwork.Status.INACTIVA)

    def test_non_transaction_event_is_acknowledged_without_changes(self):
        r = self._post(signed_wompi_event(self._transaction("APPROVED"), event="nequi_token.updated"))
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    def test_declined_event_cancels_order_and_releases_artwork(self):
        r = self._post(signed_wompi_event(self._transaction("DECLINED")))
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.CANCELADO)
        self.assertEqual(self.artwork.status, Artwork.Status.DISPONIBLE)

    # --- idempotencia ---------------------------------------------------------

    def test_late_declined_event_does_not_cancel_paid_order(self):
        self._post(signed_wompi_event(self._transaction("APPROVED")))
        r = self._post(signed_wompi_event(self._transaction("DECLINED", id="wompi-test-002")))
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PAGADO)
        self.assertEqual(self.artwork.status, Artwork.Status.VENDIDA)

    def test_duplicate_approved_event_notifies_once(self):
        payload = signed_wompi_event(self._transaction("APPROVED"))
        self.assertEqual(self._post(payload).status_code, 200)
        self.assertEqual(self._post(payload).status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PAGADO)
        self.assertEqual(NotificationLog.objects.filter(notification_type="PAYMENT_WEBHOOK").count(), 1)
        self.assertEqual(Transaction.objects.filter(order=self.order).count(), 1)

    def test_refund_after_payment_marks_order_refunded(self):
        self._post(signed_wompi_event(self._transaction("APPROVED")))
        r = self._post(signed_wompi_event(self._transaction("REFUNDED")))
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.REEMBOLSADO)

    def test_approved_event_after_cancellation_does_not_reopen_order(self):
        self._post(signed_wompi_event(self._transaction("DECLINED")))
        self._post(signed_wompi_event(self._transaction("APPROVED", id="wompi-test-003")))
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.CANCELADO)
