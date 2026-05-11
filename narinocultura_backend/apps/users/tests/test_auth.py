from rest_framework.test import APITestCase

from apps.users.models import EmailVerification, User


class AuthFlowTests(APITestCase):
    def test_register_verify_login(self):
        payload = {
            "email": "test@example.com",
            "password": "StrongPass123!",
            "first_name": "Test",
            "last_name": "User",
            "role": "COMPRADOR",
        }
        r = self.client.post("/api/v1/auth/register/", payload, format="json")
        self.assertEqual(r.status_code, 201)

        user = User.objects.get(email="test@example.com")
        self.assertFalse(user.is_verified)

        verification = EmailVerification.objects.filter(user=user, used=False).latest("created_at")
        r = self.client.post("/api/v1/auth/verify-email/", {"token": verification.token}, format="json")
        self.assertEqual(r.status_code, 200)

        user.refresh_from_db()
        self.assertTrue(user.is_verified)

        r = self.client.post(
            "/api/v1/auth/login/",
            {"email": "test@example.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(r.status_code, 200)
        self.assertIn("access", r.data)
        self.assertIn("refresh", r.data)

