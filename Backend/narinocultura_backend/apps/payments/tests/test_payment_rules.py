import unittest
import uuid

from django.test import TestCase
from rest_framework.test import APIClient

from apps.artworks.models import Artwork
from apps.marketplace.models import Order, OrderItem
from apps.notifications.models import NotificationLog
from apps.payments.models import Transaction
from services.payment_service import PaymentService
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory
from tests.wompi import signed_wompi_event

INITIATE_URL = "/api/v1/payments/initiate/"
WEBHOOK_URL = "/api/v1/payments/wompi-webhook/"


class InitiatePaymentRulesTests(TestCase):
    """Solo se paga una orden propia y PENDIENTE."""

    def setUp(self):
        self.client = APIClient()
        self.buyer = UserFactory()
        self.order = Order.objects.create(buyer=self.buyer, total_amount="80000.00")
        self.client.force_authenticate(user=self.buyer)

    def test_unknown_order_returns_400(self):
        r = self.client.post(INITIATE_URL, {"order_id": str(uuid.uuid4())}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("no encontrada", r.data["detail"])
        self.assertFalse(Transaction.objects.exists())

    def test_paid_order_cannot_be_paid_again(self):
        Order.objects.filter(id=self.order.id).update(status=Order.Status.PAGADO)
        r = self.client.post(INITIATE_URL, {"order_id": str(self.order.id)}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("PENDIENTE", r.data["detail"])
        self.assertFalse(Transaction.objects.exists())

    def test_invalid_order_id_is_rejected(self):
        r = self.client.post(INITIATE_URL, {"order_id": "no-es-un-uuid"}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_anonymous_cannot_initiate(self):
        self.client.force_authenticate(user=None)
        r = self.client.post(INITIATE_URL, {"order_id": str(self.order.id)}, format="json")
        self.assertEqual(r.status_code, 401)

    def test_returns_amount_in_cents_and_integrity_signature(self):
        r = self.client.post(INITIATE_URL, {"order_id": str(self.order.id)}, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["amount_in_cents"], 8000000)
        self.assertEqual(r.data["reference"], str(self.order.id))
        self.assertEqual(len(r.data["integrity_signature"]), 64)


class WompiWebhookEdgeCaseTests(TestCase):
    """Eventos firmados pero incompletos o inesperados: nunca deben alterar la orden por error."""

    def setUp(self):
        self.client = APIClient()
        self.buyer = UserFactory()
        self.artwork = ArtworkFactory(artist=ArtistProfileFactory(), status=Artwork.Status.INACTIVA)
        self.order = Order.objects.create(buyer=self.buyer, total_amount="200000.00")
        OrderItem.objects.create(order=self.order, artwork=self.artwork, price="200000.00")

    def _transaction(self, status="APPROVED", **overrides):
        tx = {
            "id": "wompi-edge-001",
            "status": status,
            "reference": str(self.order.id),
            "amount_in_cents": 20000000,
            "currency": "COP",
            "payment_method_type": "NEQUI",
        }
        tx.update(overrides)
        return tx

    def _post(self, payload):
        return self.client.post(WEBHOOK_URL, payload, format="json")

    def _refresh(self):
        self.order.refresh_from_db()
        self.artwork.refresh_from_db()

    def test_non_object_body_returns_401(self):
        self.assertEqual(self._post([{"event": "transaction.updated"}]).status_code, 401)

    def test_signed_property_missing_from_data_returns_401(self):
        payload = signed_wompi_event(self._transaction())
        payload["signature"]["properties"] = ["transaction.id", "transaction.inexistente"]
        self.assertEqual(self._post(payload).status_code, 401)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    def test_event_without_reference_returns_400(self):
        r = self._post(signed_wompi_event(self._transaction(reference="")))
        self.assertEqual(r.status_code, 400)
        self.assertIn("referencia", r.data["detail"])
        self.assertFalse(Transaction.objects.exists())

    def test_event_for_unknown_order_returns_400(self):
        r = self._post(signed_wompi_event(self._transaction(reference=str(uuid.uuid4()))))
        self.assertEqual(r.status_code, 400)
        self.assertFalse(Transaction.objects.exists())

    def test_currency_mismatch_returns_400(self):
        r = self._post(signed_wompi_event(self._transaction(currency="USD")))
        self.assertEqual(r.status_code, 400)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    def test_pending_event_records_transaction_without_touching_order(self):
        r = self._post(signed_wompi_event(self._transaction("PENDING")))
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)
        self.assertEqual(self.artwork.status, Artwork.Status.INACTIVA)
        tx = Transaction.objects.get(order=self.order)
        self.assertEqual(tx.status, Transaction.Status.PENDIENTE)
        self.assertEqual(tx.wompi_transaction_id, "wompi-edge-001")
        self.assertEqual(tx.payment_method, "NEQUI")
        self.assertFalse(NotificationLog.objects.filter(notification_type="PAYMENT_WEBHOOK").exists())

    def test_unknown_wompi_status_is_treated_as_pending(self):
        self.assertEqual(PaymentService._map_status("ALGO_NUEVO"), Transaction.Status.PENDIENTE)
        self._post(signed_wompi_event(self._transaction("ALGO_NUEVO")))
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PENDIENTE)

    def test_voided_event_cancels_but_keeps_artwork_that_was_not_reserved(self):
        # La obra ya no estaba reservada: el rechazo no la vuelve a poner a la venta
        Artwork.objects.filter(id=self.artwork.id).update(status=Artwork.Status.VENDIDA)
        r = self._post(signed_wompi_event(self._transaction("VOIDED")))
        self.assertEqual(r.status_code, 200)
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.CANCELADO)
        self.assertEqual(self.artwork.status, Artwork.Status.VENDIDA)

    def test_new_wompi_attempt_creates_a_second_transaction(self):
        self._post(signed_wompi_event(self._transaction("DECLINED", id="intento-1")))
        Order.objects.filter(id=self.order.id).update(status=Order.Status.PENDIENTE)
        self._post(signed_wompi_event(self._transaction("APPROVED", id="intento-2")))
        ids = set(Transaction.objects.filter(order=self.order).values_list("wompi_transaction_id", flat=True))
        self.assertEqual(ids, {"intento-1", "intento-2"})
        self._refresh()
        self.assertEqual(self.order.status, Order.Status.PAGADO)

    # BUG: services/payment_service.py:134 filtra Order por `id=reference` sin validar que la
    # referencia sea un UUID. Un evento firmado con una referencia ajena (p. ej. un link de pago
    # creado en el panel de Wompi) lanza django.core.exceptions.ValidationError, que la vista no
    # captura: responde 500 y Wompi reintenta el evento indefinidamente. Debería responder 400.
    @unittest.expectedFailure
    def test_non_uuid_reference_returns_400(self):
        client = APIClient(raise_request_exception=False)
        with self.assertLogs("django.request", level="WARNING"):
            r = client.post(WEBHOOK_URL, signed_wompi_event(self._transaction(reference="LINK-123")), format="json")
        self.assertEqual(r.status_code, 400)
