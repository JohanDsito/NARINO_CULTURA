from unittest.mock import patch

from django.utils import timezone
from rest_framework.test import APITestCase

from apps.users.models import EmailVerification, PasswordReset, User
from tests.factories import AdminUserFactory, UserFactory


class RegisterTests(APITestCase):
    def _register(self, **overrides):
        payload = {
            "email": "new@test.com",
            "password": "StrongPass123!",
            "first_name": "Test",
            "last_name": "User",
            "role": "COMPRADOR",
        }
        payload.update(overrides)
        return self.client.post("/api/v1/auth/register/", payload, format="json")

    def test_register_creates_unverified_user(self):
        r = self._register()
        self.assertEqual(r.status_code, 201)
        user = User.objects.get(email="new@test.com")
        self.assertFalse(user.is_verified)
        self.assertTrue(EmailVerification.objects.filter(user=user, used=False).exists())

    def test_register_duplicate_email_fails(self):
        UserFactory(email="dup@test.com")
        r = self._register(email="dup@test.com")
        self.assertEqual(r.status_code, 400)

    def test_register_invalid_role_fails(self):
        r = self._register(role="SUPERUSER")
        self.assertEqual(r.status_code, 400)

    def test_register_weak_password_fails(self):
        r = self._register(password="123")
        self.assertEqual(r.status_code, 400)


class EmailVerificationTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="verify@test.com",
            password="StrongPass123!",
            role="COMPRADOR",
            is_verified=False,
        )
        self.verification = EmailVerification.issue_for_user(self.user)

    def test_verify_email_via_post(self):
        r = self.client.post(
            "/api/v1/auth/verify-email/",
            {"token": self.verification.token},
            format="json",
        )
        self.assertEqual(r.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_verified)

    def test_verify_email_via_get_link(self):
        r = self.client.get(f"/api/v1/auth/verify-email/?token={self.verification.token}")
        self.assertEqual(r.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_verified)

    def test_verify_invalid_token_fails(self):
        r = self.client.post("/api/v1/auth/verify-email/", {"token": "bad-token"}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_verify_expired_token_fails(self):
        self.verification.expires_at = timezone.now() - timezone.timedelta(hours=1)
        self.verification.save()
        r = self.client.post(
            "/api/v1/auth/verify-email/",
            {"token": self.verification.token},
            format="json",
        )
        self.assertEqual(r.status_code, 400)


class LoginTests(APITestCase):
    def setUp(self):
        self.user = UserFactory(email="login@test.com", is_verified=True)
        self.user.set_password("StrongPass123!")
        self.user.save()

    def test_login_returns_tokens(self):
        r = self.client.post(
            "/api/v1/auth/login/",
            {"email": "login@test.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(r.status_code, 200)
        self.assertIn("access", r.data)
        self.assertIn("refresh", r.data)

    def test_login_unverified_user_fails(self):
        unverified = UserFactory(email="unverified@test.com", is_verified=False)
        unverified.set_password("StrongPass123!")
        unverified.save()
        r = self.client.post(
            "/api/v1/auth/login/",
            {"email": "unverified@test.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertNotEqual(r.status_code, 200)

    def test_login_wrong_password_fails(self):
        r = self.client.post(
            "/api/v1/auth/login/",
            {"email": "login@test.com", "password": "WrongPassword!"},
            format="json",
        )
        self.assertNotEqual(r.status_code, 200)


class PasswordResetTests(APITestCase):
    def setUp(self):
        self.user = UserFactory(email="reset@test.com", is_verified=True)
        self.user.set_password("OldPass123!")
        self.user.save()

    def test_request_reset_for_existing_email(self):
        r = self.client.post(
            "/api/v1/auth/password-reset/",
            {"email": "reset@test.com"},
            format="json",
        )
        self.assertEqual(r.status_code, 200)
        self.assertTrue(PasswordReset.objects.filter(user=self.user, used=False).exists())

    def test_request_reset_for_nonexistent_email_returns_200(self):
        r = self.client.post(
            "/api/v1/auth/password-reset/",
            {"email": "nobody@test.com"},
            format="json",
        )
        # Should not reveal whether email exists
        self.assertEqual(r.status_code, 200)

    def test_confirm_reset_changes_password(self):
        reset = PasswordReset.issue_for_user(self.user)
        r = self.client.post(
            "/api/v1/auth/password-reset/confirm/",
            {"token": reset.token, "new_password": "NewSecure456!"},
            format="json",
        )
        self.assertEqual(r.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NewSecure456!"))

    def test_confirm_reset_invalid_token_fails(self):
        r = self.client.post(
            "/api/v1/auth/password-reset/confirm/",
            {"token": "bad-token", "new_password": "NewSecure456!"},
            format="json",
        )
        self.assertEqual(r.status_code, 400)


class GestorCulturalRegistrationRestrictionTests(APITestCase):
    """Ensure privileged roles cannot self-register."""

    def _register(self, role):
        return self.client.post(
            "/api/v1/auth/register/",
            {"email": f"{role.lower()}@test.com", "password": "StrongPass123!", "first_name": "X", "last_name": "Y", "role": role},
            format="json",
        )

    def test_register_as_gestor_cultural_fails(self):
        r = self._register("GESTOR_CULTURAL")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(User.objects.filter(role="GESTOR_CULTURAL").exists())

    def test_register_as_administrador_fails(self):
        r = self._register("ADMINISTRADOR")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(User.objects.filter(role="ADMINISTRADOR").exists())

    def test_register_as_artista_succeeds(self):
        r = self._register("ARTISTA")
        self.assertEqual(r.status_code, 201)

    def test_register_as_comprador_succeeds(self):
        r = self._register("COMPRADOR")
        self.assertEqual(r.status_code, 201)


class AdminCreateUserTests(APITestCase):
    """Admin endpoint to create users with any role, including GESTOR_CULTURAL."""

    def setUp(self):
        self.admin = AdminUserFactory()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self._get_token(self.admin)}")

    def _get_token(self, user):
        from rest_framework_simplejwt.tokens import RefreshToken
        return str(RefreshToken.for_user(user).access_token)

    def _payload(self, **overrides):
        data = {"email": "gestor@narino.gov", "first_name": "María", "last_name": "López", "role": "GESTOR_CULTURAL"}
        data.update(overrides)
        return data

    @patch("apps.administration.views.EmailService.send_admin_created_account_email")
    def test_admin_creates_gestor_cultural(self, mock_email):
        mock_email.return_value = type("R", (), {"ok": True})()
        r = self.client.post("/api/v1/admin/users/", self._payload(), format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["role"], "GESTOR_CULTURAL")
        user = User.objects.get(email="gestor@narino.gov")
        self.assertTrue(user.is_verified)
        mock_email.assert_called_once()

    @patch("apps.administration.views.EmailService.send_admin_created_account_email")
    def test_admin_creates_administrador(self, mock_email):
        mock_email.return_value = type("R", (), {"ok": True})()
        r = self.client.post("/api/v1/admin/users/", self._payload(email="admin2@test.com", role="ADMINISTRADOR"), format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["role"], "ADMINISTRADOR")

    def test_nonadmin_cannot_create_user(self):
        buyer = UserFactory(email="buyer@test.com", role="COMPRADOR")
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self._get_token(buyer)}")
        r = self.client.post("/api/v1/admin/users/", self._payload(), format="json")
        self.assertEqual(r.status_code, 403)

    def test_unauthenticated_cannot_create_user(self):
        self.client.credentials()
        r = self.client.post("/api/v1/admin/users/", self._payload(), format="json")
        self.assertEqual(r.status_code, 401)

    @patch("apps.administration.views.EmailService.send_admin_created_account_email")
    def test_duplicate_email_fails(self, mock_email):
        mock_email.return_value = type("R", (), {"ok": True})()
        UserFactory(email="gestor@narino.gov")
        r = self.client.post("/api/v1/admin/users/", self._payload(), format="json")
        self.assertEqual(r.status_code, 400)


class FullAuthFlowTests(APITestCase):
    """Integration test for the complete happy path."""

    def test_register_verify_login_logout(self):
        # 1. Register
        r = self.client.post(
            "/api/v1/auth/register/",
            {"email": "flow@test.com", "password": "Flow1234!", "first_name": "F", "last_name": "L", "role": "COMPRADOR"},
            format="json",
        )
        self.assertEqual(r.status_code, 201)

        # 2. Verify email
        user = User.objects.get(email="flow@test.com")
        token = EmailVerification.objects.get(user=user, used=False).token
        self.client.post("/api/v1/auth/verify-email/", {"token": token}, format="json")

        # 3. Login
        r = self.client.post(
            "/api/v1/auth/login/",
            {"email": "flow@test.com", "password": "Flow1234!"},
            format="json",
        )
        self.assertEqual(r.status_code, 200)
        refresh = r.data["refresh"]
        access = r.data["access"]

        # 4. Access protected endpoint
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        r = self.client.get("/api/v1/users/me/")
        self.assertEqual(r.status_code, 200)

        # 5. Logout
        r = self.client.post("/api/v1/auth/logout/", {"refresh": refresh}, format="json")
        self.assertEqual(r.status_code, 200)


class JWTRoleClaimTests(APITestCase):
    """Verify that JWT tokens include the 'role' claim."""

    def setUp(self):
        self.user = UserFactory(email="jwt@test.com", role="ARTISTA", is_verified=True)
        self.user.set_password("StrongPass123!")
        self.user.save()

    def test_jwt_includes_role_claim(self):
        """Login should return JWT with 'role' claim."""
        r = self.client.post(
            "/api/v1/auth/login/",
            {"email": "jwt@test.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(r.status_code, 200)

        # Decode JWT to check role claim
        import jwt
        from django.conf import settings

        token = r.data["access"]
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])

        self.assertIn("role", decoded)
        self.assertEqual(decoded["role"], "ARTISTA")

    def test_jwt_role_claim_for_different_roles(self):
        """Different roles should be included in JWT."""
        roles = ["COMPRADOR", "GESTOR_CULTURAL", "ADMINISTRADOR"]

        for role in roles:
            user = UserFactory(email=f"user-{role}@test.com", role=role, is_verified=True)
            user.set_password("StrongPass123!")
            user.save()

            r = self.client.post(
                "/api/v1/auth/login/",
                {"email": f"user-{role}@test.com", "password": "StrongPass123!"},
                format="json",
            )
            self.assertEqual(r.status_code, 200)

            import jwt
            from django.conf import settings

            token = r.data["access"]
            decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            self.assertEqual(decoded["role"], role)


class DeleteAccountTests(APITestCase):
    """Test account deletion functionality."""

    def setUp(self):
        self.user = UserFactory(email="delete@test.com", is_verified=True)
        self.user.set_password("StrongPass123!")
        self.user.save()

    def _get_token(self, user):
        from rest_framework_simplejwt.tokens import RefreshToken
        return str(RefreshToken.for_user(user).access_token)

    def test_delete_account_requires_authentication(self):
        """Delete account endpoint requires authentication."""
        r = self.client.delete(
            "/api/v1/auth/delete-account/",
            {"password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(r.status_code, 401)

    def test_delete_account_requires_password(self):
        """Delete account requires password confirmation."""
        token = self._get_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        r = self.client.delete("/api/v1/auth/delete-account/", {}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("contraseña", r.data["detail"].lower())

    def test_delete_account_with_wrong_password_fails(self):
        """Delete account with wrong password should fail."""
        token = self._get_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        r = self.client.delete(
            "/api/v1/auth/delete-account/",
            {"password": "WrongPassword!"},
            format="json",
        )
        self.assertEqual(r.status_code, 400)

    def test_delete_account_with_correct_password_succeeds(self):
        """Delete account with correct password should succeed."""
        token = self._get_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        user_id = self.user.id

        r = self.client.delete(
            "/api/v1/auth/delete-account/",
            {"password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(r.status_code, 204)

        # Verify user is deleted
        self.assertFalse(User.objects.filter(id=user_id).exists())

    def test_deleted_account_cannot_login(self):
        """After deletion, user cannot login with same credentials."""
        # First delete
        token = self._get_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        r = self.client.delete(
            "/api/v1/auth/delete-account/",
            {"password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(r.status_code, 204)

        # Try to login with deleted account
        self.client.credentials()  # Clear auth
        r = self.client.post(
            "/api/v1/auth/login/",
            {"email": "delete@test.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(r.status_code, 401)
