from django.conf import settings
from django.db import models

from utils.models import TimeStampedUUIDModel


class NotificationLog(TimeStampedUUIDModel):
    class Status(models.TextChoices):
        ENVIADO = "ENVIADO", "Enviado"
        FALLIDO = "FALLIDO", "Fallido"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL
    )
    notification_type = models.CharField(max_length=100)
    payload = models.JSONField(default=dict, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices)
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["notification_type", "-sent_at"]),
            models.Index(fields=["status", "-sent_at"]),
        ]

    def __str__(self):
        return f"{self.notification_type} - {self.status}"

