from __future__ import annotations

from decimal import Decimal

from django.db import transaction

from apps.artworks.models import Artwork
from apps.marketplace.models import Cart, CartItem, Order, OrderItem
from services.notification_service import NotificationService


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
        order = Order.objects.create(buyer=user, total_amount=total, status=Order.Status.PENDIENTE, order_type=order_type)
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

