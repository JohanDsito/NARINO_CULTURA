from __future__ import annotations

import logging
from datetime import timedelta
from decimal import Decimal

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.artworks.models import Artwork
from apps.marketplace.models import Cart, CartItem, Order, OrderItem
from services.notification_service import NotificationService

logger = logging.getLogger("apps.marketplace")


class MarketplaceService:
    @staticmethod
    def get_or_create_cart(*, user) -> Cart:
        cart, _ = Cart.objects.get_or_create(user=user)
        return cart

    @staticmethod
    @transaction.atomic
    def add_to_cart(*, user, artwork_id) -> CartItem:
        cart = MarketplaceService.get_or_create_cart(user=user)
        artwork = Artwork.objects.select_for_update().filter(id=artwork_id).first()
        if not artwork:
            raise ValueError("La obra no existe.")
        if artwork.status != Artwork.Status.DISPONIBLE:
            raise ValueError("La obra no está disponible para compra.")
        item, created = CartItem.objects.get_or_create(cart=cart, artwork=artwork)
        if not created:
            raise ValueError("La obra ya está en el carrito.")
        return item

    @staticmethod
    @transaction.atomic
    def remove_from_cart(*, user, artwork_id) -> None:
        cart = MarketplaceService.get_or_create_cart(user=user)
        deleted, _ = CartItem.objects.filter(cart=cart, artwork_id=artwork_id).delete()
        if not deleted:
            raise ValueError("La obra no está en el carrito.")

    @staticmethod
    @transaction.atomic
    def checkout(*, user, order_type: str) -> Order:
        cart = MarketplaceService.get_or_create_cart(user=user)
        items = (
            CartItem.objects.select_related("artwork", "artwork__artist", "artwork__artist__user")
            .select_for_update()
            .filter(cart=cart)
        )
        if not items.exists():
            raise ValueError("El carrito está vacío.")

        artworks = [i.artwork for i in items]
        for artwork in artworks:
            if artwork.status != Artwork.Status.DISPONIBLE:
                raise ValueError("Hay obras en el carrito que ya no están disponibles.")

        total = sum((a.price for a in artworks), Decimal("0.00"))
        # La compra directa reserva las obras (INACTIVA) solo durante el plazo de pago: si no se paga,
        # expire_unpaid_direct_orders las devuelve al catálogo. Antes quedaban reservadas para siempre.
        due = (
            timezone.now() + timedelta(hours=settings.DIRECT_ORDER_PAYMENT_HOURS)
            if order_type == Order.Type.COMPRA_DIRECTA
            else None
        )
        order = Order.objects.create(
            buyer=user, total_amount=total, status=Order.Status.PENDIENTE, order_type=order_type, payment_due_at=due
        )
        for artwork in artworks:
            OrderItem.objects.create(order=order, artwork=artwork, price=artwork.price)
            artwork.status = Artwork.Status.INACTIVA
            artwork.save(update_fields=["status", "updated_at"])

        items.delete()
        NotificationService.send(
            "ORDER_CREATED",
            {"order_id": str(order.id), "buyer_id": str(user.id), "total_amount": str(order.total_amount), "order_type": order.order_type},
            user=user,
        )
        return order

    @staticmethod
    def expire_unpaid_direct_orders() -> int:
        """Cancela las compras directas cuyo plazo de pago venció y devuelve sus obras al catálogo.

        No toca una orden con un pago ya iniciado en Wompi (transacción PENDIENTE con id de Wompi, p. ej. un
        PSE en curso): ese pago se resuelve con el webhook, que la aprueba o la cancela y libera las obras."""
        from apps.payments.models import Transaction

        expired_ids = list(
            Order.objects.filter(
                order_type=Order.Type.COMPRA_DIRECTA,
                status=Order.Status.PENDIENTE,
                payment_due_at__lte=timezone.now(),
            ).values_list("id", flat=True)
        )
        expired = 0
        for order_id in expired_ids:
            with transaction.atomic():
                # Se vuelve a leer con bloqueo: el webhook de pago pudo confirmarla mientras tanto
                order = Order.objects.select_for_update().filter(id=order_id, status=Order.Status.PENDIENTE).first()
                if not order:
                    continue
                paying = Transaction.objects.filter(
                    order=order, status=Transaction.Status.PENDIENTE
                ).exclude(wompi_transaction_id="")
                if paying.exists():
                    continue
                order.status = Order.Status.CANCELADO
                order.save(update_fields=["status", "updated_at"])
                for item in order.items.select_related("artwork"):
                    if item.artwork.status == Artwork.Status.INACTIVA:
                        item.artwork.status = Artwork.Status.DISPONIBLE
                        item.artwork.save(update_fields=["status", "updated_at"])
                NotificationService.send(
                    "ORDER_RESERVATION_EXPIRED",
                    {"order_id": str(order.id), "total_amount": str(order.total_amount)},
                    user=order.buyer,
                )
                expired += 1
        if expired:
            logger.info("Compras directas vencidas: %d", expired)
        return expired

