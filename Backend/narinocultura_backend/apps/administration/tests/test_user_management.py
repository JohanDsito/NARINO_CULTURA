"""Gestión de usuarios y registros de notificaciones desde el panel de administración."""
import unittest
from datetime import timedelta
from decimal import Decimal
from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.administration.serializers import AdminUserSerializer
from apps.marketplace.models import Order, OrderItem
from apps.notifications.models import NotificationLog
from apps.users.models import User
from services.email_service import EmailResult
from tests.factories import AdminUserFactory, ArtworkFactory, UserFactory

USERS_URL = "/api/v1/admin/users/"
LOG_URL = "/api/v1/admin/notifications/log/"


class AdminUserListTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory()
        self.with_avatar = UserFactory(avatar=SimpleUploadedFile("a.png", b"img", content_type="image/png"))
        # Fechas fijas: creados en el mismo milisegundo, el orden por created_at quedaría al azar
        ahora = timezone.now()
        User.objects.filter(pk=self.admin.pk).update(created_at=ahora - timedelta(days=1))
        User.objects.filter(pk=self.with_avatar.pk).update(created_at=ahora)

    def test_admin_lists_users_newest_first_with_avatars(self):
        self.client.force_authenticate(user=self.admin)
        r = self.client.get(USERS_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual([row["email"] for row in r.data], [self.with_avatar.email, self.admin.email])
        avatars = {row["email"]: row["avatar_url"] for row in r.data}
        self.assertTrue(avatars[self.with_avatar.email].startswith("http://testserver/"))
        self.assertEqual(avatars[self.admin.email], "")

    def test_serializer_without_request_returns_relative_avatar(self):
        url = AdminUserSerializer(self.with_avatar).data["avatar_url"]
        self.assertIn("avatars/", url)
        self.assertFalse(url.startswith("http"))

    def test_non_admin_gets_403(self):
        self.client.force_authenticate(user=self.with_avatar)
        self.assertEqual(self.client.get(USERS_URL).status_code, 403)

    def test_anonymous_gets_401(self):
        self.assertEqual(self.client.get(USERS_URL).status_code, 401)


class AdminCreateUserEmailTests(APITestCase):
    def setUp(self):
        self.client.force_authenticate(user=AdminUserFactory())
        self.payload = {"email": "gestor@test.com", "first_name": "Gloria", "last_name": "Rosero", "role": "GESTOR_CULTURAL"}

    @patch("apps.administration.views.EmailService.send_admin_created_account_email")
    def test_created_user_can_log_in_with_emailed_password(self, mock_email):
        mock_email.return_value = EmailResult(ok=True)
        r = self.client.post(USERS_URL, self.payload, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertTrue(r.data["is_verified"])
        kwargs = mock_email.call_args.kwargs
        self.assertEqual(kwargs["user_name"], "Gloria Rosero")
        self.assertEqual(kwargs["role_display"], "Gestor cultural")
        user = User.objects.get(email="gestor@test.com")
        self.assertTrue(user.check_password(kwargs["temp_password"]))
        self.assertEqual(user.phone, "")

    @patch("apps.administration.views.EmailService.send_admin_created_account_email")
    def test_email_failure_is_logged_but_user_is_created(self, mock_email):
        mock_email.return_value = EmailResult(ok=False, error_message="SMTP caído")
        with self.assertLogs("apps.administration.views", level="WARNING") as logs:
            r = self.client.post(USERS_URL, self.payload, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertIn("SMTP caído", logs.output[0])
        self.assertTrue(User.objects.filter(email="gestor@test.com").exists())

    def test_invalid_role_is_rejected(self):
        r = self.client.post(USERS_URL, {**self.payload, "role": "SUPERUSUARIO"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("role", r.data)


class AdminUserDetailTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory()
        self.user = UserFactory(email="cliente@test.com")
        self.url = f"{USERS_URL}{self.user.id}/"
        self.client.force_authenticate(user=self.admin)

    def test_admin_retrieves_user(self):
        r = self.client.get(self.url)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["email"], "cliente@test.com")

    def test_admin_changes_role_and_deactivates_but_not_email(self):
        r = self.client.patch(
            self.url, {"role": "ARTISTA", "is_active": False, "email": "otro@test.com"}, format="json"
        )
        self.assertEqual(r.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.role, "ARTISTA")
        self.assertFalse(self.user.is_active)
        self.assertEqual(self.user.email, "cliente@test.com")

    def test_admin_deletes_user(self):
        r = self.client.delete(self.url)
        self.assertEqual(r.status_code, 204)
        self.assertFalse(User.objects.filter(id=self.user.id).exists())

    def test_unknown_user_returns_404(self):
        r = self.client.get(f"{USERS_URL}00000000-0000-0000-0000-000000000000/")
        self.assertEqual(r.status_code, 404)

    # BUG: AdminUserDetailAPIView (apps/administration/views.py:74) usa el destroy genérico y no
    # captura ProtectedError: borrar a un artista con obras vendidas (OrderItem.artwork PROTECT) da 500.
    @unittest.expectedFailure
    def test_delete_artist_with_sold_artworks_returns_conflict(self):
        artwork = ArtworkFactory(status="VENDIDA")
        order = Order.objects.create(buyer=UserFactory(), total_amount=Decimal("150000.00"))
        OrderItem.objects.create(order=order, artwork=artwork, price=Decimal("150000.00"))
        self.client.raise_request_exception = False
        r = self.client.delete(f"{USERS_URL}{artwork.artist.user_id}/")
        self.assertEqual(r.status_code, 409)

    def test_non_admin_cannot_manage_users(self):
        self.client.force_authenticate(user=self.user)
        self.assertEqual(self.client.get(self.url).status_code, 403)
        self.assertEqual(self.client.patch(self.url, {"role": "ADMINISTRADOR"}, format="json").status_code, 403)
        self.assertEqual(self.client.delete(self.url).status_code, 403)
        self.user.refresh_from_db()
        self.assertEqual(self.user.role, "COMPRADOR")


class AdminNotificationLogTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory()
        self.user = UserFactory()
        NotificationLog.objects.create(user=self.user, notification_type="ORDER_PAID", status="ENVIADO")
        NotificationLog.objects.create(user=None, notification_type="SYSTEM", status="SIN_CORREO")

    def test_admin_sees_log_with_optional_user_email(self):
        self.client.force_authenticate(user=self.admin)
        r = self.client.get(LOG_URL)
        self.assertEqual(r.status_code, 200)
        emails = {row["notification_type"]: row["user_email"] for row in r.data}
        self.assertEqual(emails, {"ORDER_PAID": self.user.email, "SYSTEM": None})

    def test_non_admin_gets_403(self):
        self.client.force_authenticate(user=self.user)
        self.assertEqual(self.client.get(LOG_URL).status_code, 403)

    def test_transactions_and_metrics_require_admin(self):
        self.client.force_authenticate(user=self.user)
        self.assertEqual(self.client.get("/api/v1/admin/transactions/").status_code, 403)
        self.assertEqual(self.client.get("/api/v1/admin/metrics/").status_code, 403)
