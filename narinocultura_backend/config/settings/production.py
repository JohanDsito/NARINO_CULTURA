from .base import *  # noqa: F401,F403

DEBUG = False
if SECRET_KEY == "unsafe-secret-key-change-me":
    raise RuntimeError("SECRET_KEY no configurada para producción.")

# Configuraciones para producción
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

