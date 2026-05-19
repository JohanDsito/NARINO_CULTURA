from __future__ import annotations

from decimal import Decimal

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction
from django.utils import timezone

from apps.auctions.models import Auction, Bid
from apps.artworks.models import Artwork
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
            status=Auction.Status.ACTIVA,
        )
        artwork.status = Artwork.Status.EN_SUBASTA
        artwork.save(update_fields=["status", "updated_at"])
        NotificationService.send("AUCTION_OPENED", {"auction_id": str(auction.id), "artwork_id": str(artwork.id)}, user=seller)
        return auction

    @staticmethod
    @transaction.atomic
    def place_bid(*, auction: Auction, bidder, amount: Decimal) -> Bid:
        if not bidder.is_authenticated:
            raise ValueError("Autenticación requerida.")
        if auction.status != Auction.Status.ACTIVA:
            raise ValueError("La subasta no está activa.")

        now = timezone.now()
        if now < auction.starts_at:
            raise ValueError("La subasta aún no ha iniciado.")
        if now >= auction.ends_at:
            AuctionService._close_if_ended(auction_id=auction.id)
            raise ValueError("La subasta ya finalizó.")

        locked = Auction.objects.select_for_update().get(id=auction.id)
        if amount <= locked.current_price:
            raise ValueError("La puja debe ser mayor al precio actual.")

        bid = Bid.objects.create(auction=locked, bidder=bidder, amount=amount)
        locked.current_price = amount
        locked.highest_bidder = bidder
        locked.save(update_fields=["current_price", "highest_bidder", "updated_at"])

        AuctionService._broadcast(
            auction_id=str(locked.id),
            payload={
                "type": "bid",
                "auction_id": str(locked.id),
                "amount": str(amount),
                "bidder_id": str(bidder.id),
                "current_price": str(locked.current_price),
                "ends_at": locked.ends_at.isoformat(),
            },
        )
        NotificationService.send(
            "AUCTION_BID",
            {"auction_id": str(locked.id), "amount": str(amount), "bidder_id": str(bidder.id)},
            user=bidder,
        )
        return bid

    @staticmethod
    @transaction.atomic
    def close_auction(*, auction: Auction, actor) -> Auction:
        locked = Auction.objects.select_for_update().select_related("artwork").get(id=auction.id)
        if locked.status != Auction.Status.ACTIVA:
            raise ValueError("La subasta ya fue cerrada o cancelada.")
        if actor.id != locked.seller_id and getattr(actor, "role", None) != "ADMINISTRADOR":
            raise ValueError("No tienes permisos para cerrar esta subasta.")

        locked.status = Auction.Status.CERRADA
        locked.winner_id = locked.highest_bidder_id
        locked.save(update_fields=["status", "winner", "updated_at"])

        artwork = locked.artwork
        if locked.winner_id:
            artwork.status = Artwork.Status.INACTIVA
        else:
            artwork.status = Artwork.Status.DISPONIBLE
        artwork.save(update_fields=["status", "updated_at"])

        AuctionService._broadcast(
            auction_id=str(locked.id),
            payload={"type": "closed", "auction_id": str(locked.id), "winner_id": str(locked.winner_id) if locked.winner_id else None},
        )
        NotificationService.send("AUCTION_CLOSED", {"auction_id": str(locked.id), "winner_id": str(locked.winner_id) if locked.winner_id else None}, user=actor)
        return locked

    @staticmethod
    def _broadcast(*, auction_id: str, payload: dict) -> None:
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f"auction_{auction_id}",
            {"type": "auction_event", "payload": payload},
        )

    @staticmethod
    @transaction.atomic
    def _close_if_ended(*, auction_id) -> None:
        locked = Auction.objects.select_for_update().select_related("artwork").filter(id=auction_id).first()
        if not locked or locked.status != Auction.Status.ACTIVA:
            return
        if timezone.now() < locked.ends_at:
            return
        locked.status = Auction.Status.CERRADA
        locked.winner_id = locked.highest_bidder_id
        locked.save(update_fields=["status", "winner", "updated_at"])
        locked.artwork.status = Artwork.Status.INACTIVA if locked.winner_id else Artwork.Status.DISPONIBLE
        locked.artwork.save(update_fields=["status", "updated_at"])

