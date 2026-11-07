from django.core import mail
from django.core.cache import cache
from django.test import override_settings
from rest_framework.test import APITestCase

from apps.users.models import EmailVerification
from tests.factories import UserFactory

URL = "/api/v1/auth/resend-verification/"
LOCMEM = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache", "LOCATION": "resend-test"}}


class ResendVerificationTests(APITestCase):
    """POST /auth/resend-verification/ (pedido de la app móvil)."""

    def setUp(self):
        self.pending = UserFactory(email="nueva@test.com", is_verified=False, first_name="Ana")
        self.old = EmailVerification.issue_for_user(self.pending)

    def test_sends_new_link_to_unverified_account(self):
        r = self.client.post(URL, {"email": "nueva@test.com"}, format="json")
        self.assertEqual(r.status_code, 200)
        (email,) = mail.outbox
        self.assertEqual(email.to, ["nueva@test.com"])
        self.assertIn("Hola Ana,", email.alternatives[0][0])

    def test_previous_links_stop_working(self):
        self.client.post(URL, {"email": "nueva@test.com"}, format="json")
        self.old.refresh_from_db()
        self.assertTrue(self.old.used)
        latest = EmailVerification.objects.filter(user=self.pending, used=False).get()
        r = self.client.post("/api/v1/auth/verify-email/", {"token": latest.token}, format="json")
        self.assertEqual(r.status_code, 200)
        r = self.client.post("/api/v1/auth/verify-email/", {"token": self.old.token}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_email_is_case_insensitive(self):
        self.client.post(URL, {"email": "NUEVA@Test.com"}, format="json")
        self.assertEqual(len(mail.outbox), 1)

    def test_same_answer_for_unknown_or_verified_accounts(self):
        """No revela si el correo existe ni si ya está verificado."""
        UserFactory(email="lista@test.com", is_verified=True)
        expected = self.client.post(URL, {"email": "nueva@test.com"}, format="json").data
        for email in ("lista@test.com", "nadie@test.com"):
            r = self.client.post(URL, {"email": email}, format="json")
            self.assertEqual(r.status_code, 200)
            self.assertEqual(r.data, expected)
        self.assertEqual(len(mail.outbox), 1)  # solo la cuenta pendiente

    def test_email_is_required(self):
        self.assertEqual(self.client.post(URL, {}, format="json").status_code, 400)

    @override_settings(CACHES=LOCMEM)
    def test_is_limited_to_three_per_hour(self):
        cache.clear()
        codes = [self.client.post(URL, {"email": "nueva@test.com"}, format="json").status_code for _ in range(4)]
        self.assertEqual(codes, [200, 200, 200, 429])
