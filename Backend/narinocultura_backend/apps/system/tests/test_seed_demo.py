import os
import runpy
from io import StringIO
from unittest.mock import patch

from django.conf import settings
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase

from apps.artworks.models import Artwork
from apps.auctions.models import Auction
from apps.events.models import Event
from apps.system.management.commands.seed_demo import (
    ADMIN_EMAIL,
    ARTIST_EMAIL,
    BUYER_EMAIL,
    DEMO_PASSWORD,
)
from apps.users.models import User


def sembrar(ambiente="config.settings.e2e", confirmar=True):
    out = StringIO()
    with patch.dict(os.environ, {"DJANGO_SETTINGS_MODULE": ambiente}):
        call_command("seed_demo", *(["--confirmar"] if confirmar else []), stdout=out)
    return out.getvalue()


class SeedDemoGuardTests(TestCase):
    def test_se_niega_en_produccion(self):
        with self.assertRaises(CommandError) as ctx:
            sembrar("config.settings.production")
        self.assertIn("seed_demo solo corre", str(ctx.exception))
        self.assertFalse(User.objects.exists())

    def test_se_niega_sin_ambiente(self):
        with patch.dict(os.environ, {}, clear=False):
            os.environ.pop("DJANGO_SETTINGS_MODULE", None)
            with self.assertRaises(CommandError):
                call_command("seed_demo", "--confirmar", stdout=StringIO())

    def test_se_niega_dentro_de_railway(self):
        with patch.dict(os.environ, {"RAILWAY_ENVIRONMENT": "production"}):
            with self.assertRaises(CommandError) as ctx:
                sembrar("config.settings.development")
        self.assertIn("Railway", str(ctx.exception))
        self.assertFalse(User.objects.exists())

    def test_se_niega_contra_la_base_de_railway(self):
        for host in ("postgres.railway.internal", "monorail.proxy.rlwy.net"):
            # SQLite ignora HOST: cambiarlo solo afecta lo que ve el comando
            with self.subTest(host=host), patch.dict(settings.DATABASES["default"], {"HOST": host}):
                with self.assertRaises(CommandError):
                    sembrar("config.settings.development")
        self.assertFalse(User.objects.exists())

    def test_exige_confirmar(self):
        with self.assertRaises(CommandError) as ctx:
            sembrar(confirmar=False)
        self.assertIn("--confirmar", str(ctx.exception))
        self.assertFalse(User.objects.exists())

    def test_permite_development(self):
        sembrar("config.settings.development")
        self.assertTrue(User.objects.filter(email=ADMIN_EMAIL).exists())


class SeedDemoTests(TestCase):
    def test_crea_usuarios_obras_subasta_y_evento(self):
        salida = sembrar()
        self.assertIn("listos", salida)

        admin = User.objects.get(email=ADMIN_EMAIL)
        self.assertEqual(admin.role, "ADMINISTRADOR")
        self.assertTrue(admin.is_staff and admin.is_verified)
        self.assertTrue(admin.check_password(DEMO_PASSWORD))
        self.assertEqual(User.objects.get(email=ARTIST_EMAIL).role, "ARTISTA")
        self.assertEqual(User.objects.get(email=BUYER_EMAIL).role, "COMPRADOR")

        self.assertEqual(Artwork.objects.filter(status="DISPONIBLE").count(), 4)
        subasta = Auction.objects.get()
        self.assertEqual(subasta.status, "ACTIVA")
        self.assertLess(subasta.starts_at, subasta.ends_at)
        self.assertTrue(Event.objects.get().is_published)

    def test_es_idempotente_y_reabre_la_subasta(self):
        sembrar()
        subasta = Auction.objects.get()
        Auction.objects.filter(pk=subasta.pk).update(ends_at=subasta.starts_at)
        User.objects.filter(email=BUYER_EMAIL).update(is_verified=False)

        sembrar()

        self.assertEqual(User.objects.count(), 3)
        self.assertEqual(Artwork.objects.count(), 5)
        self.assertEqual(Auction.objects.count(), 1)
        self.assertEqual(Event.objects.count(), 1)
        self.assertGreater(Auction.objects.get().ends_at, subasta.starts_at)
        self.assertTrue(User.objects.get(email=BUYER_EMAIL).is_verified)

    def test_no_reabre_una_subasta_cerrada(self):
        sembrar()
        Auction.objects.update(status="CERRADA")
        fin = Auction.objects.get().ends_at
        sembrar()
        self.assertEqual(Auction.objects.get().ends_at, fin)


class AjustesE2ETests(TestCase):
    """config.settings.e2e se niega a arrancar si algo apunta a Railway (producción)."""

    def cargar(self, **entorno):
        base = {k: v for k, v in os.environ.items() if not k.startswith("RAILWAY_")}
        for variable in ("DATABASE_URL", "REDIS_URL", "DB_HOST", "ALLOWED_HOSTS"):
            base.pop(variable, None)
        with patch.dict(os.environ, {**base, **entorno}, clear=True):
            return runpy.run_module("config.settings.e2e")

    def test_arranca_aislado_en_local(self):
        ajustes = self.cargar(DATABASE_URL="postgres://u:p@127.0.0.1:5432/narino_e2e")
        self.assertEqual(ajustes["DATABASES"]["default"]["HOST"], "127.0.0.1")
        self.assertEqual(ajustes["DATABASES"]["default"]["ENGINE"], "django.db.backends.postgresql")
        self.assertEqual(ajustes["EMAIL_BACKEND"], "django.core.mail.backends.locmem.EmailBackend")
        self.assertEqual(ajustes["GEMINI_API_KEY"], "")
        self.assertEqual(ajustes["REST_FRAMEWORK"]["DEFAULT_THROTTLE_CLASSES"], [])
        self.assertIn("LocMemCache", ajustes["CACHES"]["default"]["BACKEND"])
        self.assertNotIn("cloudinary_storage", ajustes["INSTALLED_APPS"])

    def test_sin_database_url_usa_sqlite(self):
        ajustes = self.cargar()
        self.assertEqual(ajustes["DATABASES"]["default"]["ENGINE"], "django.db.backends.sqlite3")

    def test_se_niega_con_urls_de_railway(self):
        casos = {
            "DATABASE_URL": "postgresql://postgres:x@monorail.proxy.rlwy.net:12345/railway",
            "REDIS_URL": "redis://default:x@redis.railway.internal:6379",
            "DB_HOST": "postgres.railway.internal",
            "ALLOWED_HOSTS": "narinocultura-production.up.railway.app",
        }
        for variable, valor in casos.items():
            with self.subTest(variable=variable), self.assertRaises(RuntimeError):
                self.cargar(**{variable: valor})

    def test_se_niega_dentro_de_railway(self):
        with self.assertRaises(RuntimeError):
            self.cargar(RAILWAY_ENVIRONMENT_NAME="production")

    def test_rechaza_bases_que_no_son_postgres(self):
        with self.assertRaises(RuntimeError):
            self.cargar(DATABASE_URL="mysql://u:p@127.0.0.1/x")
