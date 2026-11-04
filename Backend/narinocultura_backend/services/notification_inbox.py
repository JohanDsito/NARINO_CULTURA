"""Notificaciones de la bandeja de cada usuario (HU-B09).

Por cada evento de negocio decide quién debe enterarse dentro de la plataforma y con qué
texto. Los destinatarios se buscan en la base de datos: el `user` del NotificationLog es
quien provocó el evento, no necesariamente quien debe recibir el aviso."""
from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass, field

from django.contrib.auth import get_user_model
from django.db import transaction
from django.utils import formats, timezone

from services.notification_emails import format_price, parse_date_value

logger = logging.getLogger("services.notifications")


@dataclass(frozen=True)
class InboxItem:
    recipient_id: object
    title: str
    body: str
    data: dict = field(default_factory=dict)


def _when(value) -> str:
    moment = parse_date_value(value)
    if not moment:
        return ""
    return formats.date_format(timezone.localtime(moment), r"j \d\e F, g:i a").lower()


def _get(queryset, pk):
    """Busca por id; un id ausente o que no es UUID devuelve None en lugar de un error."""
    try:
        return queryset.filter(id=uuid.UUID(str(pk))).first()
    except (TypeError, ValueError):
        return None


def _auction(payload):
    from apps.auctions.models import Auction

    return _get(Auction.objects.select_related("artwork"), payload.get("auction_id"))


def _auction_data(auction) -> dict:
    return {"auction_id": str(auction.id), "url": f"/auctions/{auction.id}"}


def _auction_pending(payload):
    title = payload.get("artwork_title", "una obra")
    admins = get_user_model().objects.filter(role="ADMINISTRADOR", is_active=True).values_list("id", flat=True)
    data = {"auction_id": payload.get("auction_id"), "url": "/admin/dashboard"}
    return [
        InboxItem(admin_id, "Subasta pendiente de aprobación", f"«{title}» espera revisión para salir a subasta.", data)
        for admin_id in admins
    ]


def _auction_opened(payload):
    auction = _auction(payload)
    if not auction:
        return []
    ends = _when(payload.get("ends_at"))
    body = f"La subasta de «{auction.artwork.title}» ya está activa" + (f" hasta el {ends}." if ends else ".")
    return [InboxItem(auction.seller_id, "Tu subasta fue aprobada", body, _auction_data(auction))]


def _auction_rejected(payload):
    auction = _auction(payload)
    if not auction:
        return []
    body = f"La solicitud de subasta de «{auction.artwork.title}» no fue aprobada."
    return [InboxItem(auction.seller_id, "Subasta no aprobada", body, _auction_data(auction))]


def _auction_bid(payload):
    auction = _auction(payload)
    if not auction:
        return []
    title = auction.artwork.title
    amount = format_price(payload.get("amount"))
    items = [InboxItem(auction.seller_id, "Nueva puja en tu subasta", f"Ofrecieron {amount} por «{title}».", _auction_data(auction))]
    previous = payload.get("previous_bidder_id")
    if previous and previous != payload.get("bidder_id"):
        items.append(InboxItem(previous, "Te superaron en una subasta", f"Ahora la puja más alta por «{title}» es {amount}.", _auction_data(auction)))
    return items


def _auction_closed(payload):
    auction = _auction(payload)
    if not auction:
        return []
    title = auction.artwork.title
    price = format_price(payload.get("final_price"))
    data = _auction_data(auction)
    winner_id = payload.get("winner_id")
    if not winner_id:
        return [InboxItem(auction.seller_id, "Tu subasta cerró sin pujas", f"La obra «{title}» vuelve a estar disponible.", data)]

    due = _when(payload.get("payment_due_at"))
    winner_body = f"Ganaste «{title}» por {price}." + (f" Paga antes del {due}." if due else "")
    winner_data = {**data, "order_id": payload.get("order_id"), "url": "/orders"} if payload.get("order_id") else data
    return [
        InboxItem(winner_id, "¡Ganaste la subasta!", winner_body, winner_data),
        InboxItem(auction.seller_id, "Tu subasta cerró", f"«{title}» se adjudicó por {price}.", data),
    ]


def _auction_payment_expired(payload):
    from apps.marketplace.models import Order

    order = _get(Order.objects, payload.get("order_id"))
    if not order:
        return []
    body = "La orden de la obra que ganaste en subasta se canceló porque venció el plazo de pago."
    return [InboxItem(order.buyer_id, "Venció el plazo de pago", body, {"order_id": str(order.id), "url": "/orders"})]


def _payment_webhook(payload):
    if payload.get("status") != "APROBADO":
        return []
    from apps.marketplace.models import Order

    order = _get(Order.objects.prefetch_related("items__artwork__artist"), payload.get("order_id"))
    if not order:
        return []
    data = {"order_id": str(order.id), "url": "/orders"}
    items = [InboxItem(order.buyer_id, "Pago confirmado", f"Recibimos tu pago de {format_price(order.total_amount)}.", data)]
    for item in order.items.all():
        items.append(
            InboxItem(
                item.artwork.artist.user_id,
                "¡Vendiste una obra!",
                f"«{item.artwork.title}» se vendió por {format_price(item.price)}.",
                {"url": "/dashboard/sales"},
            )
        )
    return items


def _event_registration(payload):
    from apps.events.models import Event

    event = _get(Event.objects, payload.get("event_id"))
    if not event:
        return []
    user_id = get_user_model().objects.filter(email=payload.get("user_email")).values_list("id", flat=True).first()
    if not user_id:
        return []
    when = _when(event.start_date)
    body = f"Te inscribiste en «{event.title}»" + (f", el {when}." if when else ".")
    return [InboxItem(user_id, "Inscripción confirmada", body, {"event_id": str(event.id), "url": f"/events/{event.id}"})]


def _event_published(payload):
    from apps.events.models import Event

    event = _get(Event.objects, payload.get("event_id"))
    if not event:
        return []
    data = {"event_id": str(event.id), "url": f"/events/{event.id}"}
    return [InboxItem(event.organizer_id, "Tu evento fue publicado", f"«{event.title}» ya aparece en la agenda cultural.", data)]


BUILDERS = {
    "AUCTION_PENDING": _auction_pending,
    "AUCTION_OPENED": _auction_opened,
    "AUCTION_REJECTED": _auction_rejected,
    "AUCTION_BID": _auction_bid,
    "AUCTION_CLOSED": _auction_closed,
    "AUCTION_PAYMENT_EXPIRED": _auction_payment_expired,
    "PAYMENT_WEBHOOK": _payment_webhook,
    "EVENT_REGISTRATION": _event_registration,
    "EVENT_PUBLISHED": _event_published,
}


def build_inbox_items(notification_type: str, payload: dict) -> list[InboxItem]:
    builder = BUILDERS.get(notification_type)
    if not builder:
        return []
    try:
        # Savepoint: en PostgreSQL una consulta fallida invalidaría la transacción del llamador
        with transaction.atomic():
            return builder(payload or {})
    except Exception:
        # La bandeja es secundaria: un dato inesperado no puede tumbar la puja o el pago
        logger.exception("No se pudo construir la notificación %s", notification_type)
        return []
