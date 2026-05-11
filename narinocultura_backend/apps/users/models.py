import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from django.utils import timezone

from apps.users.managers import UserManager
from utils.models import TimeStampedUUIDModel


class User(TimeStampedUUIDModel, AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        ARTISTA = "ARTISTA", "Artista"
        COMPRADOR = "COMPRADOR", "Comprador"
        GESTOR_CULTURAL = "GESTOR_CULTURAL", "Gestor cultural"
        ADMINISTRADOR = "ADMINISTRADOR", "Administrador"

    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices)
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)
    phone = models.CharField(max_length=30, blank=True)
    avatar_url = models.URLField(blank=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["email"])]

    def __str__(self):
        return self.email


class EmailVerification(TimeStampedUUIDModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    token = models.CharField(max_length=255, unique=True, db_index=True)
    expires_at = models.DateTimeField()
    used = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["token", "used", "expires_at"])]

    def __str__(self):
        return f"EmailVerification({self.user_id})"

    @staticmethod
    def issue_for_user(user, ttl_hours: int = 24) -> "EmailVerification":
        return EmailVerification.objects.create(
            user=user,
            token=secrets.token_urlsafe(32),
            expires_at=timezone.now() + timedelta(hours=ttl_hours),
        )

    def is_valid(self) -> bool:
        return (not self.used) and self.expires_at >= timezone.now()


class PasswordReset(TimeStampedUUIDModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    token = models.CharField(max_length=255, unique=True, db_index=True)
    expires_at = models.DateTimeField()
    used = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["token", "used", "expires_at"])]

    def __str__(self):
        return f"PasswordReset({self.user_id})"

    @staticmethod
    def issue_for_user(user, ttl_hours: int = 2) -> "PasswordReset":
        return PasswordReset.objects.create(
            user=user,
            token=secrets.token_urlsafe(32),
            expires_at=timezone.now() + timedelta(hours=ttl_hours),
        )

    def is_valid(self) -> bool:
        return (not self.used) and self.expires_at >= timezone.now()

