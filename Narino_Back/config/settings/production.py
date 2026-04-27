from .base import *  # noqa: F401,F403

DEBUG = False
if SECRET_KEY == "unsafe-secret-key-change-me":
    raise RuntimeError("SECRET_KEY no configurada para producción.")

