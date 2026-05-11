from django.db import models

from apps.marketplace.models import Order
from utils.models import TimeStampedUUIDModel


class Transaction(TimeStampedUUIDModel):
    class Status(models.TextChoices):
        PENDIENTE = "PENDIENTE", "Pendiente"
        APROBADO = "APROBADO", "Aprobado"
        RECHAZADO = "RECHAZADO", "Rechazado"
        REEMBOLSADO = "REEMBOLSADO", "Reembolsado"

    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="transactions")
    wompi_transaction_id = models.CharField(max_length=120, blank=True, db_index=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default="COP")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDIENTE)
    payment_method = models.CharField(max_length=120, blank=True)
    wompi_response = models.JSONField(default=dict, blank=True)
    receipt_url = models.URLField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["order", "-created_at"]),
            models.Index(fields=["status", "-created_at"]),
        ]

    def __str__(self):
        return f"Transaction({self.id}) - {self.status}"

