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

    # Si el comprador elimina su cuenta la orden se conserva (SET_NULL): es el historial de ventas del
    # artista y el soporte contable del pago. Por eso se guarda una copia del nombre y el correo.
    buyer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="orders"
    )
    buyer_name = models.CharField(max_length=255, blank=True)
    buyer_email = models.EmailField(blank=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDIENTE)
    order_type = models.CharField(max_length=20, choices=Type.choices, default=Type.COMPRA_DIRECTA)
    # Solo para órdenes de subasta: después de esta fecha la orden se cancela y la obra se libera
    payment_due_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["buyer", "-created_at"]),
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["order_type", "status", "payment_due_at"]),
        ]
        constraints = [
            models.CheckConstraint(check=Q(total_amount__gte=0), name="order_total_gte_0"),
        ]

    def __str__(self):
        return f"Order({self.id}) - {self.status}"

    def save(self, *args, **kwargs):
        # La copia del comprador se toma al crear la orden y no cambia después
        if self.buyer_id and not self.buyer_email:
            self.buyer_name = f"{self.buyer.first_name} {self.buyer.last_name}".strip() or self.buyer.email
            self.buyer_email = self.buyer.email
            if kwargs.get("update_fields") is not None:
                kwargs["update_fields"] = {*kwargs["update_fields"], "buyer_name", "buyer_email"}
        super().save(*args, **kwargs)


class OrderItem(TimeStampedUUIDModel):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    artwork = models.ForeignKey(Artwork, on_delete=models.PROTECT)
    price = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["order", "-created_at"])]

    def __str__(self):
        return f"{self.order_id} - {self.artwork_id}"

