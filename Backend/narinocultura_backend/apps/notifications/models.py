from django.conf import settings
from django.db import models

from utils.models import TimeStampedUUIDModel


class NotificationLog(TimeStampedUUIDModel):
    class Status(models.TextChoices):
        PENDIENTE = "PENDIENTE", "Pendiente"
        ENVIADO = "ENVIADO", "Enviado"
        FALLIDO = "FALLIDO", "Fallido"
        SIN_CORREO = "SIN_CORREO", "Sin correo"

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



class Notification(TimeStampedUUIDModel):
    """Notificación de la bandeja de un usuario (campana de la web y pantalla de la app).

    A diferencia de NotificationLog, que registra el envío de cada evento de negocio, aquí hay
    una fila por destinatario con un texto pensado para mostrarse en la plataforma."""

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications"
    )
    notification_type = models.CharField(max_length=100)
    title = models.CharField(max_length=200)
    body = models.TextField(blank=True)
    # Identificadores para navegar (auction_id, order_id, event_id) y la ruta del frontend
    data = models.JSONField(default=dict, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["recipient", "-created_at"]),
            models.Index(fields=["recipient", "read_at"]),
        ]

    def __str__(self):
        return f"{self.recipient_id} - {self.title}"
