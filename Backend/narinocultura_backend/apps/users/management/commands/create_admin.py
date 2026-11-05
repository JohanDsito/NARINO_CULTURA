"""
Crea el usuario administrador inicial si todavía no existe.

Se ejecuta en cada despliegue (Procfile y Dockerfile). La contraseña nunca está en el código:
se toma de --password o de la variable de entorno ADMIN_PASSWORD. Sin contraseña no se crea
nada y el despliegue continúa. Si el administrador ya existe, no se modifica.

Uso: ADMIN_EMAIL=admin@ejemplo.com ADMIN_PASSWORD='...' python manage.py create_admin
"""
import os

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.management.base import BaseCommand

from apps.users.models import User


class Command(BaseCommand):
    help = "Crea el administrador inicial desde ADMIN_EMAIL / ADMIN_PASSWORD si no existe"

    def add_arguments(self, parser):
        parser.add_argument("--email", type=str, default=os.getenv("ADMIN_EMAIL", "admin@narino.local"))
        parser.add_argument("--password", type=str, default=os.getenv("ADMIN_PASSWORD", ""))
        parser.add_argument("--first-name", type=str, default="Admin")
        parser.add_argument("--last-name", type=str, default="User")

    def handle(self, *args, **options):
        email = options["email"]
        password = options["password"]

        # Si ya existe no se toca: nunca se restablece una contraseña en un despliegue
        if User.objects.filter(email=email).exists():
            self.stdout.write(self.style.WARNING(f"Administrador ya existe: {email}"))
            return

        if not password:
            self.stdout.write(self.style.WARNING(
                "ADMIN_PASSWORD no está configurada: no se crea el administrador inicial."
            ))
            return

        try:
            validate_password(password)
        except ValidationError as exc:
            self.stderr.write(self.style.ERROR(
                "ADMIN_PASSWORD no cumple la política de contraseñas: " + " ".join(exc.messages)
            ))
            return

        User.objects.create_user(
            email=email,
            password=password,
            first_name=options["first_name"],
            last_name=options["last_name"],
            role="ADMINISTRADOR",
            is_verified=True,
            is_active=True,
            is_staff=True,
        )
        self.stdout.write(self.style.SUCCESS(f"Administrador creado: {email}"))
