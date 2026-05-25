from .base import *  # noqa: F401,F403

DEBUG = False

if SECRET_KEY == "unsafe-secret-key-change-me":
    raise RuntimeError("SECRET_KEY no puede ser el valor por defecto en produccion.")

if not ALLOWED_HOSTS:
    raise RuntimeError("ALLOWED_HOSTS debe configurarse via variable de entorno en produccion.")

# HTTPS y headers de seguridad
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True

# Cookies seguras
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True

# Clickjacking
X_FRAME_OPTIONS = "DENY"

# Proxy confiado (Railway usa proxy inverso)
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
