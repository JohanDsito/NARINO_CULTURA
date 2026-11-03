from __future__ import annotations

import hashlib
import hmac
import logging
from decimal import Decimal

from django.conf import settings
from django.db import transaction

from apps.artworks.models import Artwork
from apps.marketplace.models import Order
from apps.payments.models import Transaction
from services.notification_service import NotificationService

logger = logging.getLogger("apps.payments")

# Transiciones de la orden que puede provocar un evento de Wompi. Cualquier otra
# combinación (p. ej. un DECLINED que llega después de un APPROVED, o un evento
# duplicado) se registra en la transacción pero no modifica la orden.
ORDER_TRANSITIONS = {
    (Order.Status.PENDIENTE, Transaction.Status.APROBADO): Order.Status.PAGADO,
    (Order.Status.PENDIENTE, Transaction.Status.RECHAZADO): Order.Status.CANCELADO,
    (Order.Status.PAGADO, Transaction.Status.REEMBOLSADO): Order.Status.REEMBOLSADO,
}


class PaymentService:
    @staticmethod
    @transaction.atomic
    def initiate_payment(*, user, order_id) -> dict:
        order = Order.objects.select_for_update().prefetch_related("items", "items__artwork").filter(id=order_id).first()
        if not order:
            raise ValueError("Orden no encontrada.")
        if getattr(user, "role", None) != "ADMINISTRADOR" and order.buyer_id != user.id:
            raise ValueError("No tienes permisos para pagar esta orden.")
        if order.status != Order.Status.PENDIENTE:
            raise ValueError("La orden no está en estado PENDIENTE.")

        tx = Transaction.objects.create(order=order, amount=order.total_amount, currency="COP", status=Transaction.Status.PENDIENTE)
        reference = str(order.id)
        amount_in_cents = PaymentService._amount_in_cents(order.total_amount)
        currency = "COP"
        signature = PaymentService._integrity_signature(reference=reference, amount_in_cents=amount_in_cents, currency=currency)

        NotificationService.send(
            "PAYMENT_INITIATED",
            {"order_id": reference, "transaction_id": str(tx.id), "amount_in_cents": amount_in_cents, "currency": currency},
            user=user,
        )
        return {
            "transaction_id": str(tx.id),
            "public_key": getattr(settings, "WOMPI_PUBLIC_KEY", ""),
            "reference": reference,
            "amount_in_cents": amount_in_cents,
            "currency": currency,
            "integrity_signature": signature,
        }

    @staticmethod
    def _integrity_signature(*, reference: str, amount_in_cents: int, currency: str) -> str:
        key = getattr(settings, "WOMPI_INTEGRITY_KEY", "")
        raw = f"{reference}{amount_in_cents}{currency}{key}".encode()
        return hashlib.sha256(raw).hexdigest()

    @staticmethod
    def _amount_in_cents(amount) -> int:
        return int((Decimal(amount) * 100).quantize(Decimal("1")))

    @staticmethod
    def event_signature_string(*, payload: dict, secret: str) -> str | None:
        """Cadena que Wompi firma: valores de `signature.properties` (rutas dentro de `data`),
        en el orden recibido, seguidos de `timestamp` y del secreto de eventos."""
        signature = payload.get("signature") or {}
        properties = signature.get("properties")
        timestamp = payload.get("timestamp")
        if not isinstance(properties, list) or not properties or timestamp in (None, ""):
            return None

        values = []
        for prop in properties:
            value = payload.get("data") or {}
            for key in str(prop).split("."):
                if not isinstance(value, dict) or key not in value:
                    return None
                value = value[key]
            values.append(str(value))
        return "".join(values) + str(timestamp) + secret

    @staticmethod
    def is_valid_event_signature(*, payload: dict, header_checksum: str = "") -> bool:
        secret = getattr(settings, "WOMPI_EVENTS_SECRET", "")
        if not secret:
            logger.error("Wompi webhook rechazado: WOMPI_EVENTS_SECRET no está configurado.")
            return False

        received = (payload.get("signature") or {}).get("checksum") or header_checksum
        raw = PaymentService.event_signature_string(payload=payload, secret=secret)
        if not received or raw is None:
            return False
        expected = hashlib.sha256(raw.encode("utf-8")).hexdigest()
        return hmac.compare_digest(expected.upper(), str(received).upper())

    @staticmethod
    @transaction.atomic
    def process_wompi_webhook(*, payload: dict) -> bool:
        """Aplica un evento `transaction.updated` ya verificado. Devuelve True si cambió la orden."""
        data = payload.get("data") or {}
        tx_data = data.get("transaction") or {}
        wompi_id = tx_data.get("id") or ""
        status = (tx_data.get("status") or "").upper()
        reference = tx_data.get("reference") or ""
        amount_in_cents = tx_data.get("amount_in_cents")
        currency = tx_data.get("currency") or "COP"
        payment_method_type = (tx_data.get("payment_method_type") or "")[:120]
        receipt_url = (tx_data.get("receipt_url") or "")[:2048]

        if not reference:
            raise ValueError("Webhook sin referencia de orden.")

        order = Order.objects.select_for_update().prefetch_related("items", "items__artwork").filter(id=reference).first()
        if not order:
            raise ValueError("Orden no encontrada para la referencia recibida.")

        if currency != "COP" or amount_in_cents != PaymentService._amount_in_cents(order.total_amount):
            logger.warning(
                "Wompi webhook: monto %s %s no coincide con la orden %s (%s COP)",
                amount_in_cents, currency, order.id, order.total_amount,
            )
            raise ValueError("El monto del pago no coincide con el total de la orden.")

        tx = (
            Transaction.objects.select_for_update()
            .filter(order=order)
            .order_by("-created_at")
            .first()
        )
        if tx and (not tx.wompi_transaction_id or tx.wompi_transaction_id == wompi_id):
            if wompi_id and not tx.wompi_transaction_id:
                tx.wompi_transaction_id = wompi_id
        else:
            tx = Transaction.objects.create(
                order=order,
                wompi_transaction_id=wompi_id,
                amount=order.total_amount,
                currency=currency,
                status=Transaction.Status.PENDIENTE,
            )

        mapped_status = PaymentService._map_status(status)
        tx.status = mapped_status
        tx.payment_method = payment_method_type
        tx.receipt_url = receipt_url
        tx.wompi_response = payload
        tx.save(update_fields=["wompi_transaction_id", "status", "payment_method", "receipt_url", "wompi_response", "updated_at"])

        new_order_status = ORDER_TRANSITIONS.get((order.status, mapped_status))
        if new_order_status is None:
            if mapped_status == Transaction.Status.APROBADO and order.status != Order.Status.PAGADO:
                logger.warning(
                    "Wompi webhook: pago aprobado %s para la orden %s en estado %s; requiere revisión manual",
                    wompi_id, order.id, order.status,
                )
            elif mapped_status != Transaction.Status.PENDIENTE:
                logger.info(
                    "Wompi webhook: evento %s ignorado para la orden %s en estado %s",
                    mapped_status, order.id, order.status,
                )
            return False

        order.status = new_order_status
        order.save(update_fields=["status", "updated_at"])
        if new_order_status == Order.Status.PAGADO:
            for item in order.items.all():
                item.artwork.status = Artwork.Status.VENDIDA
                item.artwork.save(update_fields=["status", "updated_at"])
        elif new_order_status == Order.Status.CANCELADO:
            for item in order.items.all():
                if item.artwork.status == Artwork.Status.INACTIVA:
                    item.artwork.status = Artwork.Status.DISPONIBLE
                    item.artwork.save(update_fields=["status", "updated_at"])

        NotificationService.send(
            "PAYMENT_WEBHOOK",
            {
                "order_id": str(order.id),
                "wompi_transaction_id": wompi_id,
                "status": mapped_status,
                "amount_in_cents": amount_in_cents,
                "currency": currency,
            },
        )
        return True

    @staticmethod
    def _map_status(wompi_status: str) -> str:
        if wompi_status == "APPROVED":
            return Transaction.Status.APROBADO
        if wompi_status in {"DECLINED", "ERROR", "VOIDED"}:
            return Transaction.Status.RECHAZADO
        if wompi_status in {"REFUNDED", "REVERSED"}:
            return Transaction.Status.REEMBOLSADO
        return Transaction.Status.PENDIENTE

