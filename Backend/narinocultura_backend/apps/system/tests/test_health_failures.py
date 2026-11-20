"""/health/ debe reportar 503 cuando falla la base de datos o la caché (lo usa Railway para saber si el servicio vive)."""

from unittest import mock

from django.db import OperationalError
from django.test import override_settings
from rest_framework.test import APITestCase

CACHE_REAL = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache", "LOCATION": "salud"}}


class HealthFailureTests(APITestCase):
    @override_settings(CACHES=CACHE_REAL)
    def test_todo_bien_responde_200(self):
        respuesta = self.client.get("/health/")
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data, {"status": "ok", "checks": {"database": "ok", "cache": "ok"}})

    @override_settings(CACHES=CACHE_REAL)
    def test_base_de_datos_caida_responde_503(self):
        with mock.patch("apps.system.views.connection.ensure_connection", side_effect=OperationalError):
            respuesta = self.client.get("/health/")
        self.assertEqual(respuesta.status_code, 503)
        self.assertEqual(respuesta.data["status"], "degraded")
        self.assertEqual(respuesta.data["checks"]["database"], "error")

    @override_settings(CACHES=CACHE_REAL)
    def test_cache_caida_responde_503(self):
        with mock.patch("apps.system.views.cache.set", side_effect=ConnectionError("redis caído")):
            respuesta = self.client.get("/health/")
        self.assertEqual(respuesta.status_code, 503)
        self.assertEqual(respuesta.data["checks"]["cache"], "error")

    def test_cache_que_no_guarda_queda_degradada(self):
        # La caché de pruebas (DummyCache) acepta escribir pero nunca devuelve el valor
        respuesta = self.client.get("/health/")
        self.assertEqual(respuesta.status_code, 503)
        self.assertEqual(respuesta.data["checks"]["cache"], "degraded")
