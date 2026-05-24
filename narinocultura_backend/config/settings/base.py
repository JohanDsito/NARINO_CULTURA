import os
from datetime import timedelta
from pathlib import Path
from dotenv import load_dotenv
from decouple import Csv, config
load_dotenv()
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# REDIS_URL - Define early since it's used in multiple configurations
REDIS_URL_CONFIGURED = config("REDIS_URL", default="").strip()

SECRET_KEY = config("SECRET_KEY", default="unsafe-secret-key-change-me")
DEBUG = config("DEBUG", default=False, cast=bool)

ALLOWED_HOSTS = [host for host in config(
    "ALLOWED_HOSTS",
    default="",
    cast=Csv(),
) if host]
if not ALLOWED_HOSTS:
    ALLOWED_HOSTS = [
        "localhost",
        "127.0.0.1",
        "narinocultura-production.up.railway.app",
        "*.railway.app",
    ]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "corsheaders",
    "django_filters",
    "channels",
    "drf_spectacular",
    "django_celery_beat",
    "apps.users.apps.UsersConfig",
    "apps.artists.apps.ArtistsConfig",
    "apps.artworks.apps.ArtworksConfig",
    "apps.marketplace.apps.MarketplaceConfig",
    "apps.auctions.apps.AuctionsConfig",
    "apps.payments.apps.PaymentsConfig",
    "apps.events.apps.EventsConfig",
    "apps.notifications.apps.NotificationsConfig",
    "apps.administration.apps.AdministrationConfig",
    "apps.system.apps.SystemConfig",
    "apps.musicians.apps.MusiciansConfig",
    "apps.music_discovery.apps.MusicDiscoveryConfig",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "apps.system.middleware.ActivityLogMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    }
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

DB_ENGINE = config("DB_ENGINE", default="django.db.backends.sqlite3")
if DB_ENGINE.endswith("sqlite3"):
    DATABASES = {"default": {"ENGINE": DB_ENGINE, "NAME": BASE_DIR / "db.sqlite3"}}
else:
    DATABASES = {
        "default": {
            "ENGINE": DB_ENGINE,
            "NAME": config("DB_NAME"),
            "USER": config("DB_USER"),
            "PASSWORD": config("DB_PASSWORD"),
            "HOST": config("DB_HOST"),
            "PORT": config("DB_PORT"),
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.Argon2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher",
    "django.contrib.auth.hashers.BCryptSHA256PasswordHasher",
]

LANGUAGE_CODE = "es-co"
TIME_ZONE = "America/Bogota"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

AUTH_USER_MODEL = "users.User"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_PAGINATION_CLASS": "utils.pagination.DefaultPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ),
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    # TEMPORAL: Rate limiting desactivado mientras se agrega Redis a Railway
    # TODO: Re-habilitar después de comprar espacio en Railway para Redis
    "DEFAULT_THROTTLE_CLASSES": [],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "200/hour",
        "user": "2000/hour",
        "auth_anon": "5/minute",
        "password_reset": "3/hour",
    },
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Nariño Cultura API",
    "DESCRIPTION": (
        "Plataforma de marketplace y cultura artística de la región Nariño, Colombia. "
        "Permite a artistas exhibir y subastar obras, gestores culturales organizar eventos "
        "y compradores adquirir arte de forma segura."
    ),
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
    "TAGS": [
        {"name": "auth", "description": "Autenticación y gestión de sesiones"},
        {"name": "users", "description": "Perfil de usuario"},
        {"name": "artists", "description": "Perfiles de artistas plásticos"},
        {"name": "artworks", "description": "Catálogo de obras de arte"},
        {"name": "marketplace", "description": "Carrito, órdenes y favoritos"},
        {"name": "auctions", "description": "Subastas en tiempo real"},
        {"name": "payments", "description": "Pagos e integración Wompi"},
        {"name": "events", "description": "Eventos culturales"},
        {"name": "musicians", "description": "Perfiles de músicos, bandas y solistas de Nariño"},
        {"name": "music-discovery", "description": "Descubrimiento musical con lenguaje natural"},
        {"name": "admin", "description": "Administración del sistema"},
        {"name": "system", "description": "Health check y utilidades"},
    ],
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=config("JWT_ACCESS_MINUTES", default=30, cast=int)),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=config("JWT_REFRESH_DAYS", default=7, cast=int)),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
}

CORS_ALLOWED_ORIGINS = [o for o in config("CORS_ALLOWED_ORIGINS", default="", cast=Csv()) if o]
CORS_ALLOW_ALL_ORIGINS = config(
    "CORS_ALLOW_ALL_ORIGINS",
    default=(not bool(CORS_ALLOWED_ORIGINS)),
    cast=bool,
)

CSRF_TRUSTED_ORIGINS = [o for o in config("CSRF_TRUSTED_ORIGINS", default="", cast=Csv()) if o]

# WebSockets - Usa Redis si está disponible, sino usa in-memory
if REDIS_URL_CONFIGURED:
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": [REDIS_URL_CONFIGURED],
            },
        }
    }
else:
    # TEMPORAL: Channel layer en memoria (subastas solo funcionan en una instancia)
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels.layers.InMemoryChannelLayer"
        }
    }

# Email Configuration
EMAIL_BACKEND = config("EMAIL_BACKEND", default="django.core.mail.backends.smtp.EmailBackend")
EMAIL_HOST = config("EMAIL_HOST", default="smtp.gmail.com")
EMAIL_PORT = config("EMAIL_PORT", default=587, cast=int)
EMAIL_USE_TLS = config("EMAIL_USE_TLS", default=True, cast=bool)
EMAIL_HOST_USER = config("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = config("EMAIL_HOST_PASSWORD", default="")
DEFAULT_FROM_EMAIL = config("DEFAULT_FROM_EMAIL", default="noreply@narinocultura.uk")

# Resend Configuration
RESEND_API_KEY = config("RESEND_API_KEY", default="")
RESEND_FROM_EMAIL = config("RESEND_FROM_EMAIL", default="noreply@narinocultura.uk")

# Optional Brevo Configuration (no usado por defecto)
BREVO_API_KEY = config("BREVO_API_KEY", default="")
BREVO_FROM_EMAIL = config("BREVO_FROM_EMAIL", default="noreply@narinocultura.uk")

AI_SERVICE_URL = config("AI_SERVICE_URL", default="")
FRONTEND_URL = config(
    "FRONTEND_URL",
    default=config("FRONTEND_BASE_URL", default="http://localhost:5173"),
)
API_BASE_URL = config("API_BASE_URL", default="http://localhost:8000")

WOMPI_BASE_URL = config("WOMPI_BASE_URL", default="https://sandbox.wompi.co/v1")
WOMPI_PUBLIC_KEY = config("WOMPI_PUBLIC_KEY", default="")
WOMPI_PRIVATE_KEY = config("WOMPI_PRIVATE_KEY", default="")
WOMPI_INTEGRITY_KEY = config("WOMPI_INTEGRITY_KEY", default="")

# Celery - Usa Redis si está disponible, sino ejecuta tareas sincronamente
if REDIS_URL_CONFIGURED:
    CELERY_BROKER_URL = REDIS_URL_CONFIGURED
    CELERY_RESULT_BACKEND = REDIS_URL_CONFIGURED
else:
    # TEMPORAL: Celery sin broker (tareas ejecutan sincronamente)
    CELERY_ALWAYS_EAGER = True
    CELERY_EAGER_PROPAGATES_EXCEPTIONS = True
    CELERY_BROKER_URL = "memory://"
    CELERY_RESULT_BACKEND = "cache"

CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_TIMEZONE = "America/Bogota"
CELERY_BEAT_SCHEDULE = {
    "close-expired-auctions": {
        "task": "apps.auctions.tasks.close_expired_auctions",
        "schedule": 60.0,
    },
}

# Cache - Usa Redis si está disponible, sino usa memoria local
if REDIS_URL_CONFIGURED:
    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": REDIS_URL_CONFIGURED,
            "OPTIONS": {"CLIENT_CLASS": "django_redis.client.DefaultClient"},
            "KEY_PREFIX": "narino",
        }
    }
else:
    # TEMPORAL: Fallback a cache en memoria mientras no hay Redis
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "LOCATION": "narino-cache",
        }
    }

# Media files (artwork image uploads)
USE_S3 = config("USE_S3", default=False, cast=bool)
if USE_S3:
    AWS_ACCESS_KEY_ID = config("AWS_ACCESS_KEY_ID", default="")
    AWS_SECRET_ACCESS_KEY = config("AWS_SECRET_ACCESS_KEY", default="")
    AWS_STORAGE_BUCKET_NAME = config("AWS_STORAGE_BUCKET_NAME", default="")
    AWS_S3_REGION_NAME = config("AWS_S3_REGION_NAME", default="us-east-1")
    AWS_S3_CUSTOM_DOMAIN = f"{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com"
    AWS_DEFAULT_ACL = "public-read"
    DEFAULT_FILE_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
    MEDIA_URL = f"https://{AWS_S3_CUSTOM_DOMAIN}/media/"
else:
    MEDIA_URL = "/media/"
    MEDIA_ROOT = BASE_DIR / "mediafiles"

# Structured logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "json": {
            "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
            "format": "%(asctime)s %(name)s %(levelname)s %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "json",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "WARNING",
    },
    "loggers": {
        "django": {"handlers": ["console"], "level": "WARNING", "propagate": False},
        "apps": {"handlers": ["console"], "level": "INFO", "propagate": False},
        "services": {"handlers": ["console"], "level": "INFO", "propagate": False},
    },
}

