"""
Test settings — use SQLite + in-memory cache so tests run without
PostgreSQL or Redis being available locally.
"""
# Patch Python 3.14 incompatibility: object.__copy__ was removed, breaking
# Django 5.1's BaseContext.__copy__. Apply before Django loads templates.
def _patch_django_context_copy():
    try:
        from django.template.context import BaseContext

        def _fixed_copy(self):
            duplicate = object.__new__(type(self))
            duplicate.__dict__.update({k: v for k, v in self.__dict__.items() if k != "dicts"})
            duplicate.dicts = self.dicts[:]
            return duplicate

        BaseContext.__copy__ = _fixed_copy
    except Exception:
        pass

_patch_django_context_copy()

from .base import *  # noqa: F401, F403

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
    }
}

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.dummy.DummyCache",
    }
}

# Use fast password hasher in tests to avoid Argon2 overhead
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.MD5PasswordHasher",
]

# Disable throttling in tests (throttle uses cache; DummyCache makes it pass-through anyway)
REST_FRAMEWORK = {
    **REST_FRAMEWORK,  # noqa: F405
    "DEFAULT_THROTTLE_CLASSES": [],
}

# Use in-memory email backend to avoid real SMTP calls and template copy bug in Python 3.14
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"

# Disable channel layers (no Redis needed)
CHANNEL_LAYERS = {"default": {"BACKEND": "channels.layers.InMemoryChannelLayer"}}

# No Celery tasks during tests
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
