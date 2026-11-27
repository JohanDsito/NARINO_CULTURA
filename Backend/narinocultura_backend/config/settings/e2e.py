"""
Ajustes SOLO para las pruebas end-to-end (Playwright) en local y en el CI.

Levanta el back real, pero aislado de todo servicio externo:
- sin límites de peticiones (las pruebas registran e inician sesión muchas veces seguidas),
- correo en memoria, sin llaves de IA, Resend ni Brevo,
- llaves de Wompi falsas: el webhook se firma desde la prueba con WOMPI_EVENTS_SECRET,
- sin Redis: canal de WebSockets en memoria y Celery síncrono (un solo proceso daphne basta),
- base de datos desde DATABASE_URL (Postgres en el CI) o un SQLite en archivo para correr en local.

Nunca debe apuntar a producción: si la base o los hosts mencionan railway, el arranque se detiene.
Uso: DJANGO_SETTINGS_MODULE=config.settings.e2e daphne config.asgi:application
"""
import os
from urllib.parse import unquote, urlparse

from .base import *  # noqa: F401,F403
from .base import BASE_DIR, REST_FRAMEWORK, STORAGES

DEBUG = False

SECRET_KEY = "e2e-secret-key-no-es-para-produccion"


def _database_from_env():
    """Arma DATABASES desde DATABASE_URL; sin ella usa un SQLite en archivo."""
    url = os.environ.get("DATABASE_URL", "").strip()
    if "railway" in url.lower():
        raise RuntimeError("config.settings.e2e no puede usar una base de datos de Railway (producción).")
    if not url:
        return {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": os.environ.get("E2E_SQLITE_PATH", str(BASE_DIR / "e2e.sqlite3")),
        }
    partes = urlparse(url)
    if partes.scheme not in ("postgres", "postgresql"):
        raise RuntimeError("DATABASE_URL debe ser postgres://usuario:clave@host:puerto/base")
    return {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": partes.path.lstrip("/"),
        "USER": unquote(partes.username or ""),
        "PASSWORD": unquote(partes.password or ""),
        "HOST": partes.hostname or "",
        "PORT": str(partes.port or 5432),
    }


DATABASES = {"default": _database_from_env()}

_hosts_env = os.environ.get("ALLOWED_HOSTS", "")
if "railway" in _hosts_env.lower():
    raise RuntimeError("config.settings.e2e no puede usar hosts de Railway (producción).")
ALLOWED_HOSTS = [h.strip() for h in _hosts_env.split(",") if h.strip()] or ["127.0.0.1", "localhost"]

# Cualquier origen puede llamar a la API (el front de prueba corre en otro puerto)
CORS_ALLOW_ALL_ORIGINS = True

# Hash rápido: las pruebas crean muchos usuarios
PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]

# Sin límites de peticiones. Login y registro usan sus propias clases de límite (utils/throttling.py),
# que no dependen de DEFAULT_THROTTLE_CLASSES: por eso también se suben todas las tasas.
REST_FRAMEWORK = {
    **REST_FRAMEWORK,
    "DEFAULT_THROTTLE_CLASSES": [],
    "DEFAULT_THROTTLE_RATES": {nombre: "100000/minute" for nombre in REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"]},
}

# Correos en memoria: nada sale a la red
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"

# Sin servicios externos de IA ni de correo: el código usa sus reglas locales
GEMINI_API_KEY = ""
GROQ_API_KEY = ""
RESEND_API_KEY = ""
BREVO_API_KEY = ""

# Wompi falso: las llaves no existen en la pasarela. El Web Checkout se intercepta en Playwright
# y el webhook se firma desde la prueba con el mismo secreto de eventos.
WOMPI_PUBLIC_KEY = "pub_test_e2e"
WOMPI_PRIVATE_KEY = "prv_test_e2e"
WOMPI_INTEGRITY_KEY = "test_integrity_e2e"
WOMPI_EVENTS_SECRET = "e2e_events_secret"

# Sin Redis: WebSockets y tareas en el mismo proceso
CHANNEL_LAYERS = {"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}}
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
CELERY_BROKER_URL = "memory://"
CELERY_RESULT_BACKEND = "cache+memory://"

# Archivos subidos en el disco local, nunca en Cloudinary
STORAGES = {**STORAGES, "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"}}
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "mediafiles_e2e"
