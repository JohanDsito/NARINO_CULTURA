from __future__ import annotations

import logging

from django.db import transaction

from apps.notifications.models import NotificationLog
from services.email_service import EmailService
from services.notification_emails import build_notification_email

logger = logging.getLogger("services.notifications")


class NotificationDeliveryError(Exception):
    """El proveedor de correo no aceptó el envío: la tarea lo reintenta."""


class NotificationService:
    @staticmethod
    def send(notification_type: str, payload: dict, user=None) -> NotificationLog:
        """Registra la notificación y encola su envío por correo cuando la transacción se confirma.

        Nunca hace llamadas HTTP dentro de la transacción del llamador (pujas, pagos): si la
        operación se revierte, el registro también se revierte y no se envía nada."""
        from apps.notifications.tasks import deliver_notification

        log = NotificationLog.objects.create(
            user=user if getattr(user, "is_authenticated", False) else None,
            notification_type=notification_type,
            payload=payload,
            status=NotificationLog.Status.PENDIENTE,
        )
        log_id = str(log.id)
        transaction.on_commit(lambda: NotificationService._enqueue(deliver_notification, log_id))
        return log

    @staticmethod
    def _enqueue(task, log_id: str) -> None:
        # Corre después del commit: un fallo al encolar (p. ej. Redis caído) no puede convertir
        # en error una operación que ya se guardó. El registro queda PENDIENTE para revisarlo.
        try:
            task.delay(log_id)
        except Exception:
            logger.exception("No se pudo encolar la notificación %s", log_id)

    @staticmethod
    def deliver(log_id: str) -> None:
        """Un intento de envío. Lanza NotificationDeliveryError si vale la pena reintentar."""
        log = NotificationLog.objects.select_related("user").filter(id=log_id).first()
        if not log or log.status != NotificationLog.Status.PENDIENTE:
            return

        email = build_notification_email(log)
        if email is None:
            # Tipo sin correo (p. ej. AUCTION_BID): solo queda en el historial de la plataforma
            NotificationService._set_status(log, NotificationLog.Status.SIN_CORREO)
            return

        result = EmailService.send_template(
            to=email.to, subject=email.subject, template=email.template, context=email.context
        )
        if not result.ok:
            raise NotificationDeliveryError(result.error_message or "envío fallido")
        NotificationService._set_status(log, NotificationLog.Status.ENVIADO)

    @staticmethod
    def mark_failed(log_id: str) -> None:
        log = NotificationLog.objects.filter(id=log_id, status=NotificationLog.Status.PENDIENTE).first()
        if log:
            NotificationService._set_status(log, NotificationLog.Status.FALLIDO)

    @staticmethod
    def _set_status(log: NotificationLog, status: str) -> None:
        log.status = status
        log.save(update_fields=["status", "updated_at"])
