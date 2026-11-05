import os
from io import StringIO
from unittest.mock import patch

from django.core.management import call_command
from django.test import TestCase

from apps.users.models import User

STRONG = "Nar1no-Cultura-Segura!"


def run(**options):
    out, err = StringIO(), StringIO()
    call_command("create_admin", stdout=out, stderr=err, **options)
    return out.getvalue() + err.getvalue()


@patch.dict(os.environ, {}, clear=False)
class CreateAdminCommandTests(TestCase):
    """El administrador inicial nunca se crea con una contraseña escrita en el código."""

    def setUp(self):
        os.environ.pop("ADMIN_PASSWORD", None)
        os.environ.pop("ADMIN_EMAIL", None)

    def test_without_password_creates_nothing(self):
        output = run()
        self.assertFalse(User.objects.filter(role="ADMINISTRADOR").exists())
        self.assertIn("ADMIN_PASSWORD", output)

    def test_creates_admin_from_arguments(self):
        output = run(email="admin@test.com", password=STRONG)
        admin = User.objects.get(email="admin@test.com")
        self.assertEqual(admin.role, "ADMINISTRADOR")
        self.assertTrue(admin.is_verified and admin.is_staff and admin.is_active)
        self.assertTrue(admin.check_password(STRONG))
        self.assertNotIn(STRONG, output)

    def test_existing_admin_password_is_never_reset(self):
        run(email="admin@test.com", password=STRONG)
        run(email="admin@test.com", password="Otra-Clave-Distinta-99!")
        self.assertTrue(User.objects.get(email="admin@test.com").check_password(STRONG))

    def test_weak_password_is_rejected(self):
        output = run(email="admin@test.com", password="123")
        self.assertFalse(User.objects.filter(email="admin@test.com").exists())
        self.assertIn("política", output)

    def test_old_default_password_is_not_used(self):
        run()
        self.assertFalse(User.objects.filter(email="admin@narino.local").exists())
