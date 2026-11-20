"""Reglas del UserManager y validaciones de serializers que no se alcanzan solo desde la API."""
from unittest.mock import patch

from django.test import TestCase
from rest_framework import serializers

from apps.users.models import EmailVerification, PasswordReset, User
from apps.users.serializers import LoginSerializer, RegisterSerializer
from tests.factories import UserFactory


class UserManagerTests(TestCase):
    def test_create_user_requires_email(self):
        with self.assertRaisesMessage(ValueError, "El email es obligatorio."):
            User.objects.create_user(email="", password="Clave12345")

    def test_create_user_normalizes_domain_and_hashes_password(self):
        user = User.objects.create_user(email="Ana@NARINO.COM", password="Clave12345", role="COMPRADOR")
        self.assertEqual(user.email, "Ana@narino.com")
        self.assertNotEqual(user.password, "Clave12345")
        self.assertTrue(user.check_password("Clave12345"))
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_verified)

    def test_create_superuser_sets_admin_flags(self):
        admin = User.objects.create_superuser(email="root@test.com", password="Clave12345")
        self.assertEqual(admin.role, "ADMINISTRADOR")
        self.assertTrue(admin.is_staff)
        self.assertTrue(admin.is_superuser)
        self.assertTrue(admin.is_active)
        self.assertTrue(admin.is_verified)

    def test_create_superuser_respects_explicit_values(self):
        admin = User.objects.create_superuser(email="gestor@test.com", password="Clave12345", is_verified=False)
        self.assertFalse(admin.is_verified)
        self.assertTrue(admin.is_superuser)


class SerializerDefensiveRulesTests(TestCase):
    def test_register_role_validator_rejects_unknown_role(self):
        # El ChoiceField del modelo ya filtra roles inexistentes; el validador es una segunda barrera
        with self.assertRaisesMessage(serializers.ValidationError, "Rol inválido."):
            RegisterSerializer().validate_role("SUPERUSUARIO")

    def test_register_role_validator_rejects_admin_assigned_roles(self):
        with self.assertRaisesMessage(serializers.ValidationError, "Este rol solo puede ser asignado"):
            RegisterSerializer().validate_role("GESTOR_CULTURAL")

    @patch("apps.users.serializers.authenticate")
    def test_login_rejects_inactive_user_returned_by_backend(self, mock_auth):
        # ModelBackend ya filtra inactivos; si se cambia el backend, el serializer sigue protegiendo
        mock_auth.return_value = UserFactory(is_active=False)
        serializer = LoginSerializer(data={"email": "x@test.com", "password": "Test1234!"})
        self.assertFalse(serializer.is_valid())
        self.assertEqual(serializer.errors["non_field_errors"], ["Usuario inactivo."])

    def test_login_rejects_inactive_user_through_default_backend(self):
        UserFactory(email="baja@test.com", is_active=False)
        serializer = LoginSerializer(data={"email": "baja@test.com", "password": "Test1234!"})
        self.assertFalse(serializer.is_valid())
        self.assertEqual(serializer.errors["non_field_errors"], ["Credenciales inválidas."])


class UserStrTests(TestCase):
    """Textos que muestra el admin de Django para cada registro de cuenta."""

    def test_str_representations(self):
        user = UserFactory(email="ana@test.com")
        self.assertEqual(str(user), "ana@test.com")
        self.assertEqual(str(EmailVerification.issue_for_user(user)), f"EmailVerification({user.id})")
        self.assertEqual(str(PasswordReset.issue_for_user(user)), f"PasswordReset({user.id})")
