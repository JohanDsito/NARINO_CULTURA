from __future__ import annotations

import hashlib
from decimal import Decimal

from django.conf import settings
from django.db import transaction

from apps.artworks.models import Artwork
from apps.marketplace.models import Order
from apps.payments.models import Transaction
from services.notification_service import NotificationService


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
        amount_in_cents = int((Decimal(order.total_amount) * 100).quantize(Decimal("1")))
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
        raw = f"{reference}{amount_in_cents}{currency}{key}".encode("utf-8")
        return hashlib.sha256(raw).hexdigest()

    @staticmethod
    @transaction.atomic
    def process_wompi_webhook(*, payload: dict) -> None:
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
        tx.save(update_fields=["status", "payment_method", "receipt_url", "wompi_response", "updated_at"])

        if mapped_status == Transaction.Status.APROBADO:
            order.status = Order.Status.PAGADO
            order.save(update_fields=["status", "updated_at"])
            for item in order.items.all():
                item.artwork.status = Artwork.Status.VENDIDA
                item.artwork.save(update_fields=["status", "updated_at"])
        elif mapped_status == Transaction.Status.RECHAZADO:
            order.status = Order.Status.CANCELADO
            order.save(update_fields=["status", "updated_at"])
            for item in order.items.all():
                if item.artwork.status == Artwork.Status.INACTIVA:
                    item.artwork.status = Artwork.Status.DISPONIBLE
                    item.artwork.save(update_fields=["status", "updated_at"])
        elif mapped_status == Transaction.Status.REEMBOLSADO:
            order.status = Order.Status.REEMBOLSADO
            order.save(update_fields=["status", "updated_at"])

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

    @staticmethod
    def _map_status(wompi_status: str) -> str:
        if wompi_status == "APPROVED":
            return Transaction.Status.APROBADO
        if wompi_status in {"DECLINED", "ERROR", "VOIDED"}:
            return Transaction.Status.RECHAZADO
        if wompi_status in {"REFUNDED", "REVERSED"}:
            return Transaction.Status.REEMBOLSADO
        return Transaction.Status.PENDIENTE

