from __future__ import annotations

import logging

import requests
from django.conf import settings
from django.db import transaction

from apps.notifications.models import NotificationLog

logger = logging.getLogger("services.notifications")


class NotificationDeliveryError(Exception):
    """Fallo temporal al entregar a n8n (red o error 5xx): la tarea lo reintenta."""


class NotificationService:
    @staticmethod
    def send(notification_type: str, payload: dict, user=None) -> NotificationLog:
        """Registra la notificación y encola su entrega a n8n cuando la transacción se confirma.

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
        """Un intento de entrega. Lanza NotificationDeliveryError si vale la pena reintentar."""
        log = NotificationLog.objects.select_related("user").filter(id=log_id).first()
        if not log or log.status != NotificationLog.Status.PENDIENTE:
            return

        webhook_url = getattr(settings, "N8N_WEBHOOK_URL", "")
        if not webhook_url:
            logger.warning("N8N_WEBHOOK_URL no está configurada; %s no se envió", log.notification_type)
            NotificationService._set_status(log, NotificationLog.Status.FALLIDO)
            return

        body = {"type": log.notification_type, "payload": log.payload}
        if log.user:
            body["user"] = {
                "id": str(log.user.id),
                "email": log.user.email,
                "first_name": log.user.first_name,
                "last_name": log.user.last_name,
            }

        try:
            response = requests.post(webhook_url, json=body, timeout=10)
        except requests.RequestException as exc:
            raise NotificationDeliveryError(str(exc)) from exc

        if response.status_code >= 500:
            raise NotificationDeliveryError(f"n8n respondió {response.status_code}")
        if 200 <= response.status_code < 300:
            NotificationService._set_status(log, NotificationLog.Status.ENVIADO)
        else:
            # 4xx: el flujo de n8n rechaza el mensaje; reintentar no lo arregla
            logger.warning("n8n rechazó %s con %s", log.notification_type, response.status_code)
            NotificationService._set_status(log, NotificationLog.Status.FALLIDO)

    @staticmethod
    def mark_failed(log_id: str) -> None:
        log = NotificationLog.objects.filter(id=log_id, status=NotificationLog.Status.PENDIENTE).first()
        if log:
            NotificationService._set_status(log, NotificationLog.Status.FALLIDO)

    @staticmethod
    def _set_status(log: NotificationLog, status: str) -> None:
        log.status = status
        log.save(update_fields=["status", "updated_at"])
