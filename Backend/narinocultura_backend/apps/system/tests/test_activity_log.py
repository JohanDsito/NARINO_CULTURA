"""El middleware registra en ActivityLog las peticiones que modifican datos de la API."""

from unittest import mock

from rest_framework.test import APITestCase

from apps.system.models import ActivityLog
from tests.factories import UserFactory

LOGIN = "/api/v1/auth/login/"


class ActivityLogMiddlewareTests(APITestCase):
    def test_registra_las_peticiones_que_modifican_datos(self):
        self.client.post(LOGIN, {"email": "nadie@narino.test", "password": "x"}, format="json")
        registro = ActivityLog.objects.get()
        self.assertEqual(registro.action, f"POST {LOGIN}")
        self.assertEqual(registro.entity_type, "http_request")
        self.assertIsNone(registro.user_id)
        self.assertIn("status_code", registro.metadata)

    def test_guarda_el_usuario_autenticado(self):
        usuario = UserFactory()
        self.client.force_authenticate(user=usuario)
        self.client.patch("/api/v1/users/me/", {"first_name": "Ana"}, format="json")
        self.assertEqual(ActivityLog.objects.get().user_id, usuario.id)

    def test_no_registra_lecturas_ni_rutas_fuera_de_la_api(self):
        self.client.get("/api/v1/events/")
        self.client.post("/health/")
        self.assertFalse(ActivityLog.objects.exists())

    def test_sin_celery_escribe_el_registro_directamente(self):
        with mock.patch("apps.system.tasks.create_activity_log.delay", side_effect=RuntimeError("sin broker")):
            self.client.post(LOGIN, {"email": "nadie@narino.test", "password": "x"}, format="json")
        self.assertEqual(ActivityLog.objects.get().action, f"POST {LOGIN}")

    def test_si_todo_falla_no_rompe_la_peticion(self):
        with (
            mock.patch("apps.system.tasks.create_activity_log.delay", side_effect=RuntimeError("sin broker")),
            mock.patch("apps.system.models.ActivityLog.objects.create", side_effect=RuntimeError("sin base")),
            self.assertLogs("apps.system", level="WARNING") as logs,
        ):
            respuesta = self.client.post(LOGIN, {"email": "nadie@narino.test", "password": "x"}, format="json")
        self.assertIn(respuesta.status_code, (400, 401))
        self.assertIn("ActivityLog fallback write failed", logs.output[0])
