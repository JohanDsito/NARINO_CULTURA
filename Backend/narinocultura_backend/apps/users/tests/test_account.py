"""Ciclo de vida de la cuenta: registro, verificación, tokens, perfil propio, contraseña y baja."""
import io
import unittest
from datetime import timedelta
from decimal import Decimal
from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils import timezone
from PIL import Image
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.marketplace.models import Order, OrderItem
from apps.users.models import EmailVerification, PasswordReset, User
from services.email_service import EmailResult
from tests.factories import ArtworkFactory, UserFactory

PASSWORD = "Test1234!"


def png_upload(name="avatar.png"):
    buffer = io.BytesIO()
    Image.new("RGB", (2, 2), "red").save(buffer, format="PNG")
    return SimpleUploadedFile(name, buffer.getvalue(), content_type="image/png")


class RegisterEmailFailureTests(APITestCase):
    @patch("apps.users.views.EmailService.send_verification_email")
    def test_account_is_created_even_if_email_fails(self, mock_send):
        mock_send.return_value = EmailResult(ok=False, error_message="SMTP caído")
        with self.assertLogs("apps.users.views", level="ERROR"):
            r = self.client.post(
                "/api/v1/auth/register/",
                {"email": "nuevo@test.com", "password": "StrongPass123!", "role": "ARTISTA"},
                format="json",
            )
        self.assertEqual(r.status_code, 201)
        self.assertIn("SMTP caído", r.data["detail"])
        user = User.objects.get(email="nuevo@test.com")
        self.assertFalse(user.is_verified)
        self.assertTrue(EmailVerification.objects.filter(user=user, used=False).exists())


class VerifyEmailLinkTests(APITestCase):
    URL = "/api/v1/auth/verify-email/"

    def setUp(self):
        self.user = UserFactory(is_verified=False)
        self.verification = EmailVerification.issue_for_user(self.user)

    def test_link_without_token_shows_error_page(self):
        r = self.client.get(f"{self.URL}?token=%20")
        self.assertEqual(r.status_code, 400)
        self.assertIn(b"Falta el token", r.content)

    def test_link_with_invalid_token_shows_error_page(self):
        r = self.client.get(f"{self.URL}?token=no-existe")
        self.assertEqual(r.status_code, 400)
        self.assertIn(b"Token invalido o expirado.", r.content)

    def test_token_cannot_be_used_twice(self):
        self.assertEqual(self.client.get(f"{self.URL}?token={self.verification.token}").status_code, 200)
        r = self.client.post(self.URL, {"token": self.verification.token}, format="json")
        self.assertEqual(r.status_code, 400)
        self.verification.refresh_from_db()
        self.assertTrue(self.verification.used)

    def test_post_without_token_returns_400(self):
        r = self.client.post(self.URL, {}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("token", r.data)


class ResendVerificationFailureTests(APITestCase):
    @patch("apps.users.views.EmailService.send_verification_email")
    def test_email_failure_is_logged_and_response_stays_generic(self, mock_send):
        mock_send.return_value = EmailResult(ok=False, error_message="cuota agotada")
        UserFactory(email="pend@test.com", is_verified=False)
        with self.assertLogs("apps.users.views", level="ERROR") as logs:
            r = self.client.post("/api/v1/auth/resend-verification/", {"email": "pend@test.com"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertIn("cuota agotada", logs.output[0])


class TokenRefreshTests(APITestCase):
    URL = "/api/v1/auth/token/refresh/"

    def test_valid_refresh_returns_new_access(self):
        refresh = RefreshToken.for_user(UserFactory())
        r = self.client.post(self.URL, {"refresh": str(refresh)}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertIn("access", r.data)

    def test_missing_refresh_returns_400(self):
        r = self.client.post(self.URL, {}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["detail"], "El campo refresh es obligatorio.")

    def test_invalid_refresh_returns_400(self):
        r = self.client.post(self.URL, {"refresh": "basura"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["detail"], "Refresh token invalido.")


class LogoutTests(APITestCase):
    def setUp(self):
        self.user = UserFactory()
        self.client.force_authenticate(user=self.user)

    def test_blacklisted_refresh_cannot_be_reused(self):
        refresh = str(RefreshToken.for_user(self.user))
        self.assertEqual(self.client.post("/api/v1/auth/logout/", {"refresh": refresh}, format="json").status_code, 200)
        r = self.client.post("/api/v1/auth/token/refresh/", {"refresh": refresh}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_invalid_refresh_returns_400(self):
        r = self.client.post("/api/v1/auth/logout/", {"refresh": "basura"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["detail"], "No fue posible cerrar sesion con este token.")

    def test_logout_requires_authentication(self):
        self.client.force_authenticate(user=None)
        r = self.client.post("/api/v1/auth/logout/", {"refresh": "x"}, format="json")
        self.assertEqual(r.status_code, 401)


class PasswordResetConfirmTests(APITestCase):
    URL = "/api/v1/auth/password-reset/confirm/"

    def setUp(self):
        self.user = UserFactory()
        self.reset = PasswordReset.issue_for_user(self.user)

    def test_expired_token_is_rejected_and_password_kept(self):
        PasswordReset.objects.filter(id=self.reset.id).update(expires_at=timezone.now() - timedelta(minutes=1))
        r = self.client.post(self.URL, {"token": self.reset.token, "new_password": "NuevaClave123"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password(PASSWORD))

    def test_short_new_password_is_rejected(self):
        r = self.client.post(self.URL, {"token": self.reset.token, "new_password": "corta"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("new_password", r.data)

    def test_token_is_single_use(self):
        payload = {"token": self.reset.token, "new_password": "NuevaClave123"}
        self.assertEqual(self.client.post(self.URL, payload, format="json").status_code, 200)
        self.assertEqual(self.client.post(self.URL, payload, format="json").status_code, 400)


class MeTests(APITestCase):
    URL = "/api/v1/users/me/"

    def setUp(self):
        self.user = UserFactory(first_name="Ana", role="COMPRADOR")
        self.client.force_authenticate(user=self.user)

    def test_me_returns_own_data_without_avatar(self):
        r = self.client.get(self.URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["email"], self.user.email)
        self.assertEqual(r.data["avatar_url"], "")
        self.assertNotIn("password", r.data)

    def test_update_profile_cannot_change_role_or_email(self):
        r = self.client.patch(
            self.URL, {"first_name": "Ana María", "role": "ADMINISTRADOR", "email": "x@test.com"}, format="json"
        )
        self.assertEqual(r.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, "Ana María")
        self.assertEqual(self.user.role, "COMPRADOR")
        self.assertNotEqual(self.user.email, "x@test.com")

    def test_avatar_upload_returns_absolute_url(self):
        r = self.client.patch(self.URL, {"avatar": png_upload()}, format="multipart")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["avatar_url"].startswith("http://testserver/"))
        self.assertIn("avatars/", r.data["avatar_url"])

    def test_non_image_avatar_is_rejected(self):
        fake = SimpleUploadedFile("avatar.png", b"no soy imagen", content_type="image/png")
        r = self.client.patch(self.URL, {"avatar": fake}, format="multipart")
        self.assertEqual(r.status_code, 400)
        self.assertIn("avatar", r.data)

    def test_me_requires_authentication(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get(self.URL).status_code, 401)


class ChangePasswordTests(APITestCase):
    URL = "/api/v1/users/me/password/"

    def setUp(self):
        self.user = UserFactory()
        self.client.force_authenticate(user=self.user)

    def test_wrong_current_password_is_rejected(self):
        r = self.client.patch(self.URL, {"current_password": "mala", "new_password": "NuevaClave123"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["detail"], "La contrasena actual no es correcta.")
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password(PASSWORD))

    def test_change_via_post_updates_password(self):
        r = self.client.post(self.URL, {"current_password": PASSWORD, "new_password": "NuevaClave123"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NuevaClave123"))

    def test_short_new_password_is_rejected(self):
        r = self.client.patch(self.URL, {"current_password": PASSWORD, "new_password": "123"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("new_password", r.data)

    def test_requires_authentication(self):
        self.client.force_authenticate(user=None)
        r = self.client.patch(self.URL, {"current_password": PASSWORD, "new_password": "NuevaClave123"}, format="json")
        self.assertEqual(r.status_code, 401)


class DeleteAccountWithSalesTests(APITestCase):
    """Un artista con obras vendidas no puede borrarse en cascada (OrderItem.artwork es PROTECT)."""

    URL = "/api/v1/auth/delete-account/"

    def setUp(self):
        self.artwork = ArtworkFactory(status="VENDIDA")
        self.artist = self.artwork.artist.user
        order = Order.objects.create(buyer=UserFactory(), total_amount=Decimal("150000.00"))
        OrderItem.objects.create(order=order, artwork=self.artwork, price=Decimal("150000.00"))
        self.client.force_authenticate(user=self.artist)

    def test_account_and_sales_history_are_preserved(self):
        with self.assertLogs("apps.users.views", level="ERROR"):
            self.client.delete(self.URL, {"password": PASSWORD}, format="json")
        self.assertTrue(User.objects.filter(id=self.artist.id).exists())
        self.assertTrue(OrderItem.objects.filter(artwork=self.artwork).exists())

    # BUG: DeleteAccountAPIView (apps/users/views.py:297-302) captura el ProtectedError genérico y
    # responde 500 "Intenta más tarde", aunque reintentar nunca funcionará; debería ser un 409 explicativo.
    @unittest.expectedFailure
    def test_delete_account_with_sold_artworks_returns_conflict(self):
        r = self.client.delete(self.URL, {"password": PASSWORD}, format="json")
        self.assertEqual(r.status_code, 409)
