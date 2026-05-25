"""
Django management command para crear un usuario administrador.
Uso: python manage.py create_admin --email admin@example.com --password SecurePass123!
"""
from django.core.management.base import BaseCommand
from apps.users.models import User


class Command(BaseCommand):
    help = 'Crea un usuario administrador'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            default='admin@narino.local',
            help='Email del administrador'
        )
        parser.add_argument(
            '--password',
            type=str,
            default='AdminPass123!',
            help='Contraseña del administrador'
        )
        parser.add_argument(
            '--first-name',
            type=str,
            default='Admin',
            help='Nombre del administrador'
        )
        parser.add_argument(
            '--last-name',
            type=str,
            default='User',
            help='Apellido del administrador'
        )

    def handle(self, *args, **options):
        email = options['email']
        password = options['password']
        first_name = options['first_name']
        last_name = options['last_name']

        # Si ya existe, no hacer nada (idempotente)
        if User.objects.filter(email=email).exists():
            user = User.objects.get(email=email)
            self.stdout.write(
                self.style.WARNING(f'⚠️  Administrador ya existe: {email}')
            )
            return

        # Crear el admin
        admin = User.objects.create_user(
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            role='ADMINISTRADOR',
            is_verified=True,
            is_active=True,
            is_staff=True
        )

        self.stdout.write(
            self.style.SUCCESS(f'✅ Administrador creado exitosamente')
        )
        self.stdout.write(f'   Email: {email}')
        self.stdout.write(f'   Contraseña: {password}')
