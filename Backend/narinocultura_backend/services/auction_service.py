from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.artworks.models import Artwork
from apps.auctions.models import Auction, Bid
from apps.marketplace.models import Order, OrderItem
from services.notification_service import NotificationService


class AuctionService:
    @staticmethod
    @transaction.atomic
    def create_auction(*, seller, artwork, base_price, starts_at, ends_at) -> Auction:
        if getattr(seller, "role", None) != "ARTISTA":
            raise ValueError("Solo un usuario ARTISTA puede crear subastas.")
        if artwork.artist.user_id != seller.id:
            raise ValueError("Solo puedes subastar tus propias obras.")
        if artwork.status != Artwork.Status.DISPONIBLE:
            raise ValueError("La obra debe estar DISPONIBLE para iniciar una subasta.")
        if ends_at <= starts_at:
            raise ValueError("La fecha fin debe ser mayor que la fecha inicio.")

        auction = Auction.objects.create(
            artwork=artwork,
            seller=seller,
            base_price=base_price,
            current_price=base_price,
            starts_at=starts_at,
            ends_at=ends_at,
            status=Auction.Status.PENDIENTE,
        )
        NotificationService.send("AUCTION_PENDING", {
            "auction_id": str(auction.id),
            "artwork_title": artwork.title,
            "seller_email": seller.email,
            "seller_name": f"{seller.first_name} {seller.last_name}".strip() or seller.email,
        }, user=seller)
        return auction

    @staticmethod
    @transaction.atomic
    def approve_auction(*, auction: Auction, actor) -> Auction:
        if getattr(actor, "role", None) != "ADMINISTRADOR":
            raise ValueError("Solo un administrador puede aprobar subastas.")
        locked = Auction.objects.select_for_update().select_related("artwork", "seller").get(id=auction.id)
        if locked.status != Auction.Status.PENDIENTE:
            raise ValueError("Solo se pueden aprobar subastas en estado PENDIENTE.")
        locked.status = Auction.Status.ACTIVA
        locked.save(update_fields=["status", "updated_at"])
        locked.artwork.status = Artwork.Status.EN_SUBASTA
        locked.artwork.save(update_fields=["status", "updated_at"])
        NotificationService.send("AUCTION_OPENED", {
            "auction_id": str(locked.id),
            "artwork_title": locked.artwork.title,
            "seller_email": locked.seller.email,
            "seller_name": f"{locked.seller.first_name} {locked.seller.last_name}".strip() or locked.seller.email,
            "ends_at": locked.ends_at.isoformat(),
        }, user=actor)
        return locked

    @staticmethod
    @transaction.atomic
    def reject_auction(*, auction: Auction, actor) -> Auction:
        if getattr(actor, "role", None) != "ADMINISTRADOR":
            raise ValueError("Solo un administrador puede rechazar subastas.")
        locked = Auction.objects.select_for_update().select_related("artwork", "seller").get(id=auction.id)
        if locked.status != Auction.Status.PENDIENTE:
            raise ValueError("Solo se pueden rechazar subastas en estado PENDIENTE.")
        locked.status = Auction.Status.CANCELADA
        locked.save(update_fields=["status", "updated_at"])
        NotificationService.send("AUCTION_REJECTED", {
            "auction_id": str(locked.id),
            "artwork_title": locked.artwork.title,
            "seller_email": locked.seller.email,
            "seller_name": f"{locked.seller.first_name} {locked.seller.last_name}".strip() or locked.seller.email,
        }, user=actor)
        return locked

    @staticmethod
    def place_bid(*, auction: Auction, bidder, amount: Decimal) -> Bid:
        if not bidder.is_authenticated:
            raise ValueError("Autenticación requerida.")

        with transaction.atomic():
            # Todas las validaciones se hacen sobre la fila bloqueada, para que dos pujas
            # simultáneas no vean un estado o un precio desactualizado.
            locked = Auction.objects.select_for_update().get(id=auction.id)
            if locked.seller_id == bidder.id:
                raise ValueError("No puedes pujar en tu propia subasta.")
            if locked.status != Auction.Status.ACTIVA:
                raise ValueError("La subasta no está activa.")

            now = timezone.now()
            if now < locked.starts_at:
                raise ValueError("La subasta aún no ha iniciado.")
            expired = now >= locked.ends_at
            if not expired:
                if amount <= locked.current_price:
                    raise ValueError("La puja debe ser mayor al precio actual.")

                bid = Bid.objects.create(auction=locked, bidder=bidder, amount=amount)
                locked.current_price = amount
                locked.highest_bidder = bidder
                locked.save(update_fields=["current_price", "highest_bidder", "updated_at"])

                AuctionService._broadcast_on_commit(
                    auction_id=str(locked.id),
                    payload={
                        "type": "bid_placed",
                        "auction_id": str(locked.id),
                        "amount": str(amount),
                        "current_price": str(locked.current_price),
                        "highest_bidder_id": str(bidder.id),
                        "bidder_id": str(bidder.id),
                        "bidder_name": AuctionService._public_name(bidder),
                        "ends_at": locked.ends_at.isoformat(),
                    },
                )
                NotificationService.send(
                    "AUCTION_BID",
                    {"auction_id": str(locked.id), "amount": str(amount), "bidder_id": str(bidder.id)},
                    user=bidder,
                )
                return bid

        # El cierre se hace fuera de la transacción de la puja: si se hiciera dentro,
        # el ValueError lo revertiría.
        AuctionService._close_if_ended(auction_id=auction.id)
        raise ValueError("La subasta ya finalizó.")

    @staticmethod
    @transaction.atomic
    def close_auction(*, auction: Auction, actor) -> Auction:
        locked = Auction.objects.select_for_update().select_related("artwork").get(id=auction.id)
        if locked.status != Auction.Status.ACTIVA:
            raise ValueError("La subasta ya fue cerrada o cancelada.")
        if actor.id != locked.seller_id and getattr(actor, "role", None) != "ADMINISTRADOR":
            raise ValueError("No tienes permisos para cerrar esta subasta.")
        AuctionService._finalize(locked, actor=actor)
        return locked

    @staticmethod
    @transaction.atomic
    def _close_if_ended(*, auction_id) -> None:
        locked = Auction.objects.select_for_update().select_related("artwork").filter(id=auction_id).first()
        if not locked or locked.status != Auction.Status.ACTIVA:
            return
        if timezone.now() < locked.ends_at:
            return
        AuctionService._finalize(locked, actor=None)

    @staticmethod
    def _finalize(locked: Auction, *, actor) -> None:
        """Cierra una subasta ACTIVA ya bloqueada: fija el ganador, libera o reserva la obra,
        avisa a los clientes conectados y notifica. Lo usan el cierre manual y el automático."""
        locked.status = Auction.Status.CERRADA
        locked.winner_id = locked.highest_bidder_id
        artwork = locked.artwork
        order = AuctionService._create_winner_order(locked) if locked.winner_id else None
        locked.payment_order = order
        locked.save(update_fields=["status", "winner", "payment_order", "updated_at"])

        # Con ganador, la obra queda reservada (INACTIVA) hasta que pague o venza el plazo
        artwork.status = Artwork.Status.INACTIVA if locked.winner_id else Artwork.Status.DISPONIBLE
        artwork.save(update_fields=["status", "updated_at"])

        winner_id = str(locked.winner_id) if locked.winner_id else None
        AuctionService._broadcast_on_commit(
            auction_id=str(locked.id),
            payload={
                "type": "auction_closed",
                "auction_id": str(locked.id),
                "winner_id": winner_id,
                "current_price": str(locked.current_price),
                "ends_at": locked.ends_at.isoformat(),
            },
        )

        winner = locked.winner if locked.winner_id else None
        NotificationService.send("AUCTION_CLOSED", {
            "auction_id": str(locked.id),
            "artwork_title": artwork.title,
            "winner_id": winner_id,
            "winner_email": winner.email if winner else "",
            "winner_name": (f"{winner.first_name} {winner.last_name}".strip() or winner.email) if winner else "",
            "final_price": str(locked.current_price),
            "order_id": str(order.id) if order else None,
            "payment_due_at": order.payment_due_at.isoformat() if order else None,
        }, user=actor)

    @staticmethod
    def _create_winner_order(locked: Auction) -> Order:
        due = timezone.now() + timedelta(hours=settings.AUCTION_PAYMENT_HOURS)
        order = Order.objects.create(
            buyer_id=locked.winner_id,
            total_amount=locked.current_price,
            status=Order.Status.PENDIENTE,
            order_type=Order.Type.SUBASTA,
            payment_due_at=due,
        )
        OrderItem.objects.create(order=order, artwork=locked.artwork, price=locked.current_price)
        return order

    @staticmethod
    def expire_unpaid_orders() -> int:
        """Cancela las órdenes de subasta cuyo plazo de pago venció y libera sus obras."""
        expired_ids = list(
            Order.objects.filter(
                order_type=Order.Type.SUBASTA,
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
                order.status = Order.Status.CANCELADO
                order.save(update_fields=["status", "updated_at"])
                for item in order.items.select_related("artwork"):
                    if item.artwork.status == Artwork.Status.INACTIVA:
                        item.artwork.status = Artwork.Status.DISPONIBLE
                        item.artwork.save(update_fields=["status", "updated_at"])
                NotificationService.send(
                    "AUCTION_PAYMENT_EXPIRED",
                    {
                        "order_id": str(order.id),
                        "buyer_email": order.buyer.email,
                        "total_amount": str(order.total_amount),
                    },
                    user=order.buyer,
                )
                expired += 1
        return expired

    @staticmethod
    def _public_name(user) -> str:
        # Nombre visible para los demás postores: nombre y la inicial del apellido
        initial = f" {user.last_name[:1]}." if user.last_name else ""
        return f"{user.first_name}{initial}".strip() or "Postor"

    @staticmethod
    def _broadcast_on_commit(*, auction_id: str, payload: dict) -> None:
        # Se emite solo si la transacción se confirma: los clientes nunca ven un precio revertido
        transaction.on_commit(lambda: AuctionService._broadcast(auction_id=auction_id, payload=payload))

    @staticmethod
    def _broadcast(*, auction_id: str, payload: dict) -> None:
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"auction_{auction_id}",
            {"type": "auction_event", "payload": payload},
        )
