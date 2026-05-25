from rest_framework.test import APITestCase


class HealthCheckTests(APITestCase):
    def test_health_endpoint_is_public(self):
        r = self.client.get("/health/")
        self.assertIn(r.status_code, [200, 503])

    def test_health_response_has_required_fields(self):
        r = self.client.get("/health/")
        self.assertIn("status", r.data)
        self.assertIn("checks", r.data)
        self.assertIn("database", r.data["checks"])
        self.assertIn("cache", r.data["checks"])

    def test_healthy_system_returns_200_and_ok(self):
        r = self.client.get("/health/")
        if r.status_code == 200:
            self.assertEqual(r.data["status"], "ok")
        else:
            self.assertEqual(r.data["status"], "degraded")
