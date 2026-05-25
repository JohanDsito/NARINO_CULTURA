from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.artworks.models import Artwork
from utils.models import TimeStampedUUIDModel


class Cart(TimeStampedUUIDModel):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Cart({self.user_id})"


class CartItem(TimeStampedUUIDModel):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name="items")
    artwork = models.ForeignKey(Artwork, on_delete=models.CASCADE)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["cart", "artwork"], name="uniq_cart_artwork")
        ]
        indexes = [models.Index(fields=["cart", "-created_at"])]

    def __str__(self):
        return f"{self.cart_id} - {self.artwork_id}"


class Favorite(TimeStampedUUIDModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    artwork = models.ForeignKey(Artwork, on_delete=models.CASCADE)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["user", "artwork"], name="uniq_favorite_user_artwork")
        ]

    def __str__(self):
        return f"{self.user_id} ♥ {self.artwork_id}"


class Order(TimeStampedUUIDModel):
    class Status(models.TextChoices):
        PENDIENTE = "PENDIENTE", "Pendiente"
        PAGADO = "PAGADO", "Pagado"
        CANCELADO = "CANCELADO", "Cancelado"
        REEMBOLSADO = "REEMBOLSADO", "Reembolsado"

    class Type(models.TextChoices):
        COMPRA_DIRECTA = "COMPRA_DIRECTA", "Compra directa"
        SUBASTA = "SUBASTA", "Subasta"

    buyer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="orders")
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDIENTE)
    order_type = models.CharField(max_length=20, choices=Type.choices, default=Type.COMPRA_DIRECTA)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["buyer", "-created_at"]),
            models.Index(fields=["status", "-created_at"]),
        ]
        constraints = [
            models.CheckConstraint(check=Q(total_amount__gte=0), name="order_total_gte_0"),
        ]

    def __str__(self):
        return f"Order({self.id}) - {self.status}"


class OrderItem(TimeStampedUUIDModel):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    artwork = models.ForeignKey(Artwork, on_delete=models.PROTECT)
    price = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["order", "-created_at"])]

    def __str__(self):
        return f"{self.order_id} - {self.artwork_id}"

