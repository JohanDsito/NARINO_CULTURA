"""
Siembra datos de demostración para las pruebas end-to-end y el desarrollo local.

Crea usuarios @demo.test (administrador, artista y comprador), una categoría, obras disponibles,
una subasta activa y un evento publicado. Es idempotente: se puede correr varias veces.

Por seguridad NUNCA debe correr en producción: solo se ejecuta con config.settings.e2e o
config.settings.development y con la bandera explícita --confirmar. No forma parte del Procfile
ni del Dockerfile. Las contraseñas están en el código porque son datos locales falsos.

Uso: DJANGO_SETTINGS_MODULE=config.settings.e2e python manage.py seed_demo --confirmar
"""
import os
from datetime import timedelta
from decimal import Decimal

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from apps.artists.models import ArtistProfile
from apps.artworks.models import Artwork, Category
from apps.auctions.models import Auction
from apps.events.models import Event
from apps.users.models import User

AMBIENTES_PERMITIDOS = ("config.settings.e2e", "config.settings.development")
# Hosts de la base de producción (Railway): *.railway.internal, *.proxy.rlwy.net, *.railway.app
MARCAS_PRODUCCION = ("railway", "rlwy.net")

DEMO_PASSWORD = "Demo1234!"
ADMIN_EMAIL = "admin@demo.test"
ARTIST_EMAIL = "artista@demo.test"
BUYER_EMAIL = "comprador@demo.test"

OBRAS_DISPONIBLES = (
    ("Volcán Galeras E2E", "450000"),
    ("Laguna de la Cocha E2E", "390000"),
    ("Barniz de Pasto E2E", "320000"),
    ("Carnaval de Negros y Blancos E2E", "280000"),
)
OBRA_SUBASTA = "Santuario de Las Lajas E2E"
EVENTO = "Concierto andino E2E"


class Command(BaseCommand):
    help = "Siembra usuarios @demo.test, obras, una subasta activa y un evento (solo e2e o development)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--confirmar",
            action="store_true",
            help="Confirma que entiendes que se crean usuarios con contraseña conocida",
        )

    def handle(self, *args, **options):
        ambiente = os.environ.get("DJANGO_SETTINGS_MODULE", "")
        if ambiente not in AMBIENTES_PERMITIDOS:
            raise CommandError(
                f"seed_demo solo corre con {' o '.join(AMBIENTES_PERMITIDOS)} (ambiente actual: '{ambiente}')."
            )
        # development.py hereda la base de DB_HOST: en Railway, o contra su base, se niega igual
        host_base = str(settings.DATABASES["default"].get("HOST") or "").lower()
        if any(nombre.startswith("RAILWAY_") for nombre in os.environ) or any(
            marca in host_base for marca in MARCAS_PRODUCCION
        ):
            raise CommandError("seed_demo no corre en Railway ni contra su base de datos (producción).")
        if not options["confirmar"]:
            raise CommandError("Falta la bandera --confirmar: este comando crea usuarios con contraseña conocida.")

        admin = self._usuario(ADMIN_EMAIL, "Laura", "Admin", User.Role.ADMINISTRADOR, is_staff=True)
        artista_user = self._usuario(ARTIST_EMAIL, "Ana", "Benavides", User.Role.ARTISTA)
        self._usuario(BUYER_EMAIL, "Carlos", "Díaz", User.Role.COMPRADOR)

        perfil, _ = ArtistProfile.objects.get_or_create(
            user=artista_user,
            defaults={
                "slug": "ana-barniz-e2e",
                "artistic_name": "Ana Barniz",
                "discipline": "Pintor",
                "city": "Pasto",
                "bio": "Pintora de barniz de Pasto de datos de demostración.",
                "is_public": True,
            },
        )
        categoria, _ = Category.objects.get_or_create(slug="pintura", defaults={"name": "Pintura"})

        for titulo, precio in OBRAS_DISPONIBLES:
            Artwork.objects.get_or_create(
                artist=perfil,
                title=titulo,
                defaults={
                    "price": Decimal(precio),
                    "status": Artwork.Status.DISPONIBLE,
                    "category": categoria,
                    "description": f"{titulo}: obra de demostración.",
                    "technique": "Óleo sobre lienzo",
                },
            )

        obra_subasta, _ = Artwork.objects.get_or_create(
            artist=perfil,
            title=OBRA_SUBASTA,
            defaults={
                "price": Decimal("500000"),
                "status": Artwork.Status.EN_SUBASTA,
                "category": categoria,
                "description": f"{OBRA_SUBASTA}: obra de demostración en subasta.",
            },
        )
        ahora = timezone.now()
        subasta, creada = Auction.objects.get_or_create(
            artwork=obra_subasta,
            defaults={
                "seller": artista_user,
                "base_price": Decimal("100000"),
                "current_price": Decimal("100000"),
                "status": Auction.Status.ACTIVA,
                "starts_at": ahora - timedelta(hours=1),
                "ends_at": ahora + timedelta(days=30),
            },
        )
        if not creada and subasta.status == Auction.Status.ACTIVA:
            # Al volver a sembrar, la subasta sigue abierta (el cierre vence con el tiempo)
            subasta.ends_at = ahora + timedelta(days=30)
            subasta.save(update_fields=["ends_at", "updated_at"])

        Event.objects.get_or_create(
            title=EVENTO,
            organizer=admin,
            defaults={
                "description": "Concierto de demostración en Pasto.",
                "event_type": Event.Type.CONCIERTO,
                "start_date": ahora + timedelta(days=10),
                "end_date": ahora + timedelta(days=10, hours=3),
                "location": "Teatro Imperial, Pasto",
                "is_published": True,
            },
        )

        self.stdout.write(self.style.SUCCESS(
            f"Datos de demostración listos: {ADMIN_EMAIL}, {ARTIST_EMAIL}, {BUYER_EMAIL} (clave {DEMO_PASSWORD})"
        ))

    @staticmethod
    def _usuario(email, nombre, apellido, rol, is_staff=False):
        """Crea el usuario si no existe; si existe lo deja verificado, activo y con la clave de demo."""
        usuario, _ = User.objects.get_or_create(
            email=email,
            defaults={"first_name": nombre, "last_name": apellido, "role": rol},
        )
        usuario.role = rol
        usuario.is_staff = is_staff
        usuario.is_active = True
        usuario.is_verified = True
        usuario.set_password(DEMO_PASSWORD)
        usuario.save()
        return usuario
