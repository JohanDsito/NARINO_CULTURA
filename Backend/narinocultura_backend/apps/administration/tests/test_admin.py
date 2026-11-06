from datetime import timedelta
from decimal import Decimal

from apps.marketplace.models import Order
from apps.payments.models import Transaction
from apps.users.models import User
from django.utils import timezone
from rest_framework.test import APITestCase
from tests.factories import AdminUserFactory, ArtworkFactory, UserFactory


class AdminMetricsTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory()
        self.buyer = UserFactory()
        ArtworkFactory.create_batch(2)
        self.order = Order.objects.create(buyer=self.buyer, total_amount=Decimal("250000.00"))

    def test_metrics_include_dashboard_fields(self):
        self.client.force_authenticate(user=self.admin)
        r = self.client.get("/api/v1/admin/metrics/")
        self.assertEqual(r.status_code, 200)
        for key in (
            "total_users",
            "total_artworks",
            "total_transactions",
            "new_users_last_30_days",
            "revenue_last_30_days",
        ):
            self.assertIn(key, r.data)
        self.assertEqual(r.data["total_users"], User.objects.count())
        self.assertEqual(r.data["total_artworks"], 2)

    def test_revenue_only_counts_recent_approved_transactions(self):
        Transaction.objects.create(order=self.order, amount=Decimal("100000.00"), status=Transaction.Status.APROBADO)
        Transaction.objects.create(order=self.order, amount=Decimal("50000.00"), status=Transaction.Status.RECHAZADO)
        old = Transaction.objects.create(order=self.order, amount=Decimal("70000.00"), status=Transaction.Status.APROBADO)
        Transaction.objects.filter(id=old.id).update(created_at=timezone.now() - timedelta(days=45))

        self.client.force_authenticate(user=self.admin)
        r = self.client.get("/api/v1/admin/metrics/")
        self.assertEqual(Decimal(r.data["revenue_last_30_days"]), Decimal("100000.00"))
        self.assertEqual(r.data["total_transactions"], 3)

    def test_new_users_last_30_days_excludes_old_users(self):
        old_user = UserFactory()
        User.objects.filter(id=old_user.id).update(created_at=timezone.now() - timedelta(days=60))

        self.client.force_authenticate(user=self.admin)
        r = self.client.get("/api/v1/admin/metrics/")
        self.assertEqual(r.data["new_users_last_30_days"], User.objects.count() - 1)

    def test_metrics_require_admin(self):
        self.client.force_authenticate(user=self.buyer)
        r = self.client.get("/api/v1/admin/metrics/")
        self.assertEqual(r.status_code, 403)


class AdminTransactionsTests(APITestCase):
    def test_transactions_include_order_fields(self):
        admin = AdminUserFactory()
        order = Order.objects.create(
            buyer=UserFactory(),
            total_amount=Decimal("300000.00"),
            order_type=Order.Type.SUBASTA,
        )
        Transaction.objects.create(order=order, amount=Decimal("300000.00"))

        self.client.force_authenticate(user=admin)
        r = self.client.get("/api/v1/admin/transactions/")
        self.assertEqual(r.status_code, 200)
        row = r.data[0]
        self.assertEqual(row["total_amount"], "300000.00")
        self.assertEqual(row["order_type"], "SUBASTA")
        self.assertEqual(row["order_status"], "PENDIENTE")
        self.assertEqual(row["status"], "PENDIENTE")
