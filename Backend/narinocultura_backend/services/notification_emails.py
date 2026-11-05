"""Correos que genera cada tipo de notificación de negocio.

Reemplaza la lógica que antes vivía en el flujo "Business Events" de n8n. Un tipo sin
constructor (p. ej. AUCTION_BID u ORDER_CREATED) no envía correo: solo queda en el
registro de notificaciones de la plataforma."""
from __future__ import annotations

from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation

from django.conf import settings
from django.utils import formats, timezone
from django.utils.dateparse import parse_datetime

from services.email_service import first_name


@dataclass(frozen=True)
class NotificationEmail:
    to: str
    subject: str
    template: str
    context: dict = field(default_factory=dict)


def _frontend(path: str) -> str:
    return f"{settings.FRONTEND_URL.rstrip('/')}{path}"


def format_price(value) -> str:
    try:
        amount = Decimal(str(value))
    except (InvalidOperation, TypeError):
        return ""
    return "$" + f"{amount:,.0f}".replace(",", ".") + " COP"


def parse_date_value(value):
    return parse_datetime(value) if isinstance(value, str) else value


def format_date(value) -> str:
    """Fecha legible en español y en hora de Colombia: "15 de diciembre de 2026, 8:00 p.m."."""
    moment = parse_date_value(value)
    if not moment:
        return ""
    return formats.date_format(timezone.localtime(moment), r"j \d\e F \d\e Y, g:i a").lower()


def _auction_opened(payload, log):
    return NotificationEmail(
        to=payload.get("seller_email", ""),
        subject=f"¡Tu subasta fue aprobada! — {payload.get('artwork_title', '')}",
        template="emails/notifications/auction_opened.html",
        context={
            "name": first_name(payload.get("seller_name")),
            "artwork_title": payload.get("artwork_title"),
            "details": [("Obra", payload.get("artwork_title")), ("Cierra el", format_date(payload.get("ends_at")))],
            "auction_url": _frontend(f"/auctions/{payload.get('auction_id', '')}"),
        },
    )


def _auction_rejected(payload, log):
    return NotificationEmail(
        to=payload.get("seller_email", ""),
        subject=f"Subasta no aprobada — {payload.get('artwork_title', '')}",
        template="emails/notifications/auction_rejected.html",
        context={"name": first_name(payload.get("seller_name")), "artwork_title": payload.get("artwork_title")},
    )


def _auction_closed(payload, log):
    if not payload.get("winner_email"):
        return None
    final_price = format_price(payload.get("final_price"))
    payment_due = format_date(payload.get("payment_due_at"))
    return NotificationEmail(
        to=payload["winner_email"],
        subject=f"¡Ganaste la subasta! — {payload.get('artwork_title', '')}",
        template="emails/notifications/auction_won.html",
        context={
            "name": first_name(payload.get("winner_name")),
            "artwork_title": payload.get("artwork_title"),
            "final_price": final_price,
            "payment_due": payment_due,
            "details": [("Obra", payload.get("artwork_title")), ("Precio final", final_price), ("Paga antes del", payment_due)],
            "orders_url": _frontend("/orders"),
        },
    )


def _auction_payment_expired(payload, log):
    user = log.user
    return NotificationEmail(
        to=payload.get("buyer_email", ""),
        subject="Venció el plazo de pago de tu subasta",
        template="emails/notifications/auction_payment_expired.html",
        context={
            "name": user.first_name if user else "",
            "details": [("Valor de la orden", format_price(payload.get("total_amount")))],
        },
    )


def _payment_webhook(payload, log):
    if payload.get("status") != "APROBADO":
        return None
    from apps.marketplace.models import Order

    order = Order.objects.select_related("buyer").prefetch_related("items__artwork").filter(id=payload.get("order_id")).first()
    if not order:
        return None
    titles = ", ".join(item.artwork.title for item in order.items.all())
    amount = format_price(order.total_amount)
    return NotificationEmail(
        to=order.buyer.email,
        subject="Pago confirmado — Nariño Cultura",
        template="emails/notifications/payment_approved.html",
        context={
            "name": order.buyer.first_name,
            "amount": amount,
            "details": [("Obra", titles), ("Valor pagado", amount), ("Referencia", str(order.id)[:8].upper())],
            "orders_url": _frontend("/orders"),
        },
    )


def _event_registration(payload, log):
    return NotificationEmail(
        to=payload.get("user_email", ""),
        subject=f"Inscripción confirmada — {payload.get('event_title', '')}",
        template="emails/notifications/event_registration.html",
        context={
            "name": first_name(payload.get("user_name")),
            "event_title": payload.get("event_title"),
            "details": [("Evento", payload.get("event_title")), ("Fecha", format_date(payload.get("event_date"))),
                        ("Lugar", payload.get("event_location"))],
            "event_url": _frontend(f"/events/{payload.get('event_id', '')}"),
        },
    )


BUILDERS = {
    "AUCTION_OPENED": _auction_opened,
    "AUCTION_REJECTED": _auction_rejected,
    "AUCTION_CLOSED": _auction_closed,
    "AUCTION_PAYMENT_EXPIRED": _auction_payment_expired,
    "PAYMENT_WEBHOOK": _payment_webhook,
    "EVENT_REGISTRATION": _event_registration,
}


def build_notification_email(log) -> NotificationEmail | None:
    builder = BUILDERS.get(log.notification_type)
    email = builder(log.payload or {}, log) if builder else None
    if email is None or not email.to:
        return None
    return email
