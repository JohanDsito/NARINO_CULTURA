"""Configuración de despliegue: validaciones de producción, variables de entorno y rutas de WebSocket.

Los settings se cargan en módulos aparte (import/reload) sin tocar la configuración activa de las pruebas.
"""

import importlib
import os
import runpy
import sys
from unittest import mock

from django.test import SimpleTestCase
from django.urls import resolve

import config.settings.base as base_settings

SEGURO = {
    "SECRET_KEY": "una-llave-de-produccion-de-prueba",
    "ALLOWED_HOSTS": ["api.narinocultura.test"],
    "WOMPI_EVENTS_SECRET": "secreto-de-eventos",
}


def cargar_produccion(**valores):
    """Importa config.settings.production desde cero con los valores de base indicados."""
    sys.modules.pop("config.settings.production", None)
    try:
        with mock.patch.multiple(base_settings, **{**SEGURO, **valores}):
            return importlib.import_module("config.settings.production")
    finally:
        sys.modules.pop("config.settings.production", None)


class ProductionSettingsTests(SimpleTestCase):
    def test_no_arranca_con_la_secret_key_por_defecto(self):
        with self.assertRaisesMessage(RuntimeError, "SECRET_KEY"):
            cargar_produccion(SECRET_KEY="unsafe-secret-key-change-me")

    def test_no_arranca_sin_allowed_hosts(self):
        with self.assertRaisesMessage(RuntimeError, "ALLOWED_HOSTS"):
            cargar_produccion(ALLOWED_HOSTS=[])

    def test_no_arranca_sin_el_secreto_de_eventos_de_wompi(self):
        with self.assertRaisesMessage(RuntimeError, "WOMPI_EVENTS_SECRET"):
            cargar_produccion(WOMPI_EVENTS_SECRET="")

    def test_con_credenciales_activa_https_cookies_seguras_y_cors_cerrado(self):
        prod = cargar_produccion()
        self.assertFalse(prod.DEBUG)
        self.assertFalse(prod.CORS_ALLOW_ALL_ORIGINS)
        self.assertTrue(prod.SECURE_SSL_REDIRECT)
        self.assertEqual(prod.SECURE_HSTS_SECONDS, 31536000)
        self.assertTrue(prod.SESSION_COOKIE_SECURE)
        self.assertTrue(prod.CSRF_COOKIE_SECURE)
        self.assertEqual(prod.X_FRAME_OPTIONS, "DENY")
        self.assertEqual(prod.SECURE_PROXY_SSL_HEADER, ("HTTP_X_FORWARDED_PROTO", "https"))

    def test_los_estaticos_usan_whitenoise_con_manifiesto(self):
        # Por eso el contenedor debe correr collectstatic: sin manifiesto el admin responde 500
        prod = cargar_produccion()
        self.assertEqual(
            prod.STORAGES["staticfiles"]["BACKEND"], "whitenoise.storage.CompressedManifestStaticFilesStorage"
        )


class SettingsSelectorTests(SimpleTestCase):
    def _cargar_selector(self, entorno):
        sys.modules.pop("config.settings.production", None)
        with mock.patch.dict(os.environ, {"DJANGO_ENV": entorno}), mock.patch.multiple(base_settings, **SEGURO):
            selector = importlib.reload(importlib.import_module("config.settings"))
        self.addCleanup(sys.modules.pop, "config.settings.production", None)
        return selector

    def test_django_env_production_carga_los_settings_de_produccion(self):
        self.assertFalse(self._cargar_selector("production").DEBUG)
        self.assertIn("config.settings.production", sys.modules)

    def test_sin_django_env_carga_desarrollo(self):
        self.assertTrue(self._cargar_selector("development").DEBUG)


class EnvironmentSettingsTests(SimpleTestCase):
    """base.py arma la base de datos, Redis y Cloudinary según las variables de entorno."""

    def _cargar_base(self, **entorno):
        limpio = {k: "" for k in ("REDIS_URL", "CLOUDINARY_CLOUD_NAME", "CLOUDINARY_API_KEY", "CLOUDINARY_API_SECRET")}
        with mock.patch.dict(os.environ, {**limpio, **entorno}):
            recargado = importlib.reload(base_settings)
        # Deja el módulo como estaba para las demás pruebas
        self.addCleanup(self._restaurar)
        return recargado

    def _restaurar(self):
        # mock.patch.dict ya devolvió el entorno original: basta con recargar
        importlib.reload(base_settings)

    def test_sin_variables_usa_sqlite_memoria_local_y_tareas_en_el_mismo_proceso(self):
        cfg = self._cargar_base(DB_ENGINE="django.db.backends.sqlite3")
        self.assertTrue(cfg.DATABASES["default"]["ENGINE"].endswith("sqlite3"))
        self.assertEqual(cfg.CHANNEL_LAYERS["default"]["BACKEND"], "channels.layers.InMemoryChannelLayer")
        self.assertEqual(cfg.CACHES["default"]["BACKEND"], "django.core.cache.backends.locmem.LocMemCache")
        self.assertTrue(cfg.CELERY_TASK_ALWAYS_EAGER)
        self.assertEqual(cfg.MEDIA_URL, "/media/")

    def test_postgres_toma_las_credenciales_de_las_variables(self):
        cfg = self._cargar_base(
            DB_ENGINE="django.db.backends.postgresql",
            DB_NAME="narino",
            DB_USER="app",
            DB_PASSWORD="clave",
            DB_HOST="db.interno",
            DB_PORT="5432",
        )
        db = cfg.DATABASES["default"]
        self.assertEqual(
            (db["ENGINE"], db["NAME"], db["USER"], db["HOST"], db["PORT"]),
            ("django.db.backends.postgresql", "narino", "app", "db.interno", "5432"),
        )

    def test_con_redis_lo_usan_websockets_celery_y_cache(self):
        cfg = self._cargar_base(REDIS_URL="redis://redis.interno:6379/0")
        self.assertEqual(cfg.CHANNEL_LAYERS["default"]["BACKEND"], "channels_redis.core.RedisChannelLayer")
        self.assertEqual(cfg.CHANNEL_LAYERS["default"]["CONFIG"]["hosts"], ["redis://redis.interno:6379/0"])
        self.assertEqual(cfg.CELERY_BROKER_URL, "redis://redis.interno:6379/0")
        self.assertEqual(cfg.CACHES["default"]["BACKEND"], "django_redis.cache.RedisCache")

    def test_con_cloudinary_los_archivos_subidos_van_a_cloudinary(self):
        cfg = self._cargar_base(CLOUDINARY_CLOUD_NAME="nube", CLOUDINARY_API_KEY="1", CLOUDINARY_API_SECRET="s")
        self.assertEqual(cfg.STORAGES["default"]["BACKEND"], "cloudinary_storage.storage.MediaCloudinaryStorage")
        self.assertIn("cloudinary_storage", cfg.INSTALLED_APPS)
        self.assertEqual(cfg.MEDIA_URL, "https://res.cloudinary.com/nube/")

    def test_cors_abierto_solo_si_no_hay_origenes_configurados(self):
        self.assertTrue(self._cargar_base(CORS_ALLOWED_ORIGINS="").CORS_ALLOW_ALL_ORIGINS)
        cfg = self._cargar_base(CORS_ALLOWED_ORIGINS="https://web.narinocultura.test")
        self.assertEqual(cfg.CORS_ALLOWED_ORIGINS, ["https://web.narinocultura.test"])
        self.assertFalse(cfg.CORS_ALLOW_ALL_ORIGINS)


class WebSocketRoutingTests(SimpleTestCase):
    def test_la_ruta_de_subastas_acepta_un_uuid(self):
        from config.routing import websocket_urlpatterns

        (ruta,) = websocket_urlpatterns
        match = ruta.resolve("ws/auctions/0f8fad5b-d9cb-469f-a165-70867728950e/")
        self.assertEqual(match.kwargs, {"auction_id": "0f8fad5b-d9cb-469f-a165-70867728950e"})
        self.assertIsNone(ruta.resolve("ws/auctions/no-es-un-id!/"))

    def test_la_api_rest_sigue_resolviendo(self):
        self.assertEqual(resolve("/health/").url_name, "health-check")

    def test_la_raiz_presenta_la_api(self):
        respuesta = self.client.get("/")
        self.assertEqual(respuesta.status_code, 200)
        self.assertIn("message", respuesta.json())


class AllowedHostsTests(SimpleTestCase):
    """ALLOWED_HOSTS sale de la variable de entorno; si viene vacía se usa la lista por defecto."""

    def _cargar_base(self, valor):
        with mock.patch.dict(os.environ, {"ALLOWED_HOSTS": valor}):
            return runpy.run_module("config.settings.base")

    def test_usa_los_hosts_de_la_variable_e_ignora_los_vacios(self):
        ajustes = self._cargar_base("api.narinocultura.test, ,admin.narinocultura.test")
        self.assertEqual(ajustes["ALLOWED_HOSTS"], ["api.narinocultura.test", "admin.narinocultura.test"])

    def test_sin_variable_usa_la_lista_por_defecto(self):
        ajustes = self._cargar_base("")
        self.assertIn("localhost", ajustes["ALLOWED_HOSTS"])
        self.assertIn("narinocultura-production.up.railway.app", ajustes["ALLOWED_HOSTS"])
