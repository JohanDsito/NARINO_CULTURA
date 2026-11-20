import uuid

from rest_framework.test import APITestCase

from apps.marketplace.models import Order
from apps.payments.models import Transaction
from tests.factories import AdminUserFactory, UserFactory

LIST_URL = "/api/v1/payments/transactions/"


def receipt_url(tx_id):
    return f"/api/v1/payments/transactions/{tx_id}/receipt/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class TransactionAccessTests(APITestCase):
    """Historial de pagos y comprobantes: cada comprador ve solo los suyos; el administrador ve todos."""

    def setUp(self):
        self.buyer = UserFactory()
        self.other = UserFactory()
        self.admin = AdminUserFactory()
        self.tx = self._transaction(self.buyer, receipt_url="https://sandbox.wompi.co/receipt/abc")
        self.other_tx = self._transaction(self.other)

    def _transaction(self, buyer, **extra):
        order = Order.objects.create(buyer=buyer, total_amount="50000.00")
        return Transaction.objects.create(order=order, amount="50000.00", status=Transaction.Status.APROBADO, **extra)

    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    # --- historial ------------------------------------------------------------

    def test_buyer_lists_only_own_transactions(self):
        r = self.as_user(self.buyer).get(LIST_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual([t["id"] for t in results(r)], [str(self.tx.id)])

    def test_admin_lists_every_transaction(self):
        r = self.as_user(self.admin).get(LIST_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual({t["id"] for t in results(r)}, {str(self.tx.id), str(self.other_tx.id)})

    def test_anonymous_cannot_list_transactions(self):
        self.assertEqual(self.client.get(LIST_URL).status_code, 401)

    # --- comprobante ----------------------------------------------------------

    def test_buyer_gets_own_receipt(self):
        r = self.as_user(self.buyer).get(receipt_url(self.tx.id))
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["receipt_url"], self.tx.receipt_url)

    def test_admin_gets_any_receipt(self):
        r = self.as_user(self.admin).get(receipt_url(self.tx.id))
        self.assertEqual(r.status_code, 200)

    def test_other_buyer_cannot_see_receipt(self):
        r = self.as_user(self.other).get(receipt_url(self.tx.id))
        self.assertEqual(r.status_code, 403)
        self.assertNotIn("receipt_url", r.data)

    def test_unknown_transaction_returns_404(self):
        self.assertEqual(self.as_user(self.buyer).get(receipt_url(uuid.uuid4())).status_code, 404)

    def test_transaction_without_receipt_returns_404(self):
        r = self.as_user(self.other).get(receipt_url(self.other_tx.id))
        self.assertEqual(r.status_code, 404)
        self.assertIn("no disponible", r.data["detail"])

    def test_anonymous_cannot_see_receipt(self):
        self.assertEqual(self.client.get(receipt_url(self.tx.id)).status_code, 401)

    def test_str_shows_status(self):
        self.assertIn("APROBADO", str(self.tx))
