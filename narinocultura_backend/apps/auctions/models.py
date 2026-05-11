from django.conf import settings
from django.db import models

from apps.artworks.models import Artwork
from utils.models import TimeStampedUUIDModel


class Auction(TimeStampedUUIDModel):
    class Status(models.TextChoices):
        ACTIVA = "ACTIVA", "Activa"
        CERRADA = "CERRADA", "Cerrada"
        CANCELADA = "CANCELADA", "Cancelada"

    artwork = models.OneToOneField(Artwork, on_delete=models.CASCADE, related_name="auction")
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="auctions_sold"
    )
    base_price = models.DecimalField(max_digits=12, decimal_places=2)
    current_price = models.DecimalField(max_digits=12, decimal_places=2)
    highest_bidder = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="auctions_highest",
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVA)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    winner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="auctions_won",
    )

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "ends_at"]),
            models.Index(fields=["seller", "-created_at"]),
        ]

    def __str__(self):
        return f"Auction({self.id}) - {self.status}"


class Bid(TimeStampedUUIDModel):
    auction = models.ForeignKey(Auction, on_delete=models.CASCADE, related_name="bids")
    bidder = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["auction", "-amount"]),
            models.Index(fields=["auction", "-created_at"]),
        ]

    def __str__(self):
        return f"Bid({self.amount}) - {self.auction_id}"

