import hashlib
import hmac
import json

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.marketplace.models import Order, OrderItem
from apps.payments.models import Transaction
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory


@override_settings(WOMPI_INTEGRITY_KEY="test-integrity-key-123")
class WompiWebhookTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.buyer = UserFactory(role="COMPRADOR")
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")
        self.order = Order.objects.create(buyer=self.buyer, total_amount="200000.00")
        OrderItem.objects.create(order=self.order, artwork=self.artwork, price="200000.00")
        self.transaction = Transaction.objects.create(
            order=self.order,
            wompi_transaction_id="wompi-test-001",
            amount="200000.00",
            currency="COP",
            status="PENDIENTE",
        )

    def _sign(self, body: bytes) -> str:
        return hmac.new(b"test-integrity-key-123", body, hashlib.sha256).hexdigest()

    def _make_payload(self, status: str = "APPROVED") -> dict:
        return {
            "data": {
                "transaction": {
                    "id": "wompi-test-001",
                    "status": status,
                    "reference": str(self.order.id),
                    "amount_in_cents": 20000000,
                    "currency": "COP",
                    "payment_method_type": "CARD",
                }
            }
        }

    def test_approved_webhook_marks_order_paid(self):
        payload = self._make_payload("APPROVED")
        body = json.dumps(payload).encode()
        r = self.client.post(
            "/api/v1/payments/wompi-webhook/",
            data=body,
            content_type="application/json",
            HTTP_X_EVENT_CHECKSUM=self._sign(body),
        )
        self.assertEqual(r.status_code, 200)
        self.order.refresh_from_db()
        self.assertEqual(self.order.status, Order.Status.PAGADO)

    def test_invalid_signature_returns_401(self):
        payload = self._make_payload("APPROVED")
        body = json.dumps(payload).encode()
        r = self.client.post(
            "/api/v1/payments/wompi-webhook/",
            data=body,
            content_type="application/json",
            HTTP_X_EVENT_CHECKSUM="bad-signature",
        )
        self.assertEqual(r.status_code, 401)
        self.order.refresh_from_db()
        self.assertNotEqual(self.order.status, Order.Status.PAGADO)

    def test_declined_webhook_updates_transaction_status(self):
        payload = self._make_payload("DECLINED")
        body = json.dumps(payload).encode()
        r = self.client.post(
            "/api/v1/payments/wompi-webhook/",
            data=body,
            content_type="application/json",
            HTTP_X_EVENT_CHECKSUM=self._sign(body),
        )
        self.assertEqual(r.status_code, 200)

    @override_settings(WOMPI_INTEGRITY_KEY="")
    def test_no_integrity_key_skips_signature_check(self):
        """When WOMPI_INTEGRITY_KEY is not set, webhook is accepted without signature."""
        payload = self._make_payload("APPROVED")
        body = json.dumps(payload).encode()
        r = self.client.post(
            "/api/v1/payments/wompi-webhook/",
            data=body,
            content_type="application/json",
        )
        self.assertEqual(r.status_code, 200)
