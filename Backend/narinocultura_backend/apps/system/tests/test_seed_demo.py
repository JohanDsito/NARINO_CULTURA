import os
from io import StringIO
from unittest.mock import patch

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
