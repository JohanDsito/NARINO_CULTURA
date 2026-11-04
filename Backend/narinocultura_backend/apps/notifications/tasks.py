import logging

from celery import shared_task

logger = logging.getLogger("apps.notifications")


@shared_task(bind=True, max_retries=3, ignore_result=True)
def deliver_notification(self, log_id):
    """Entrega una notificación a n8n. Reintenta errores temporales a los 30 s, 60 s y 120 s."""
    from services.notification_service import NotificationDeliveryError, NotificationService

    try:
        NotificationService.deliver(log_id)
    except NotificationDeliveryError as exc:
        if self.request.retries < self.max_retries:
            raise self.retry(exc=exc, countdown=30 * 2 ** self.request.retries) from exc
        logger.error("Notificación %s no entregada tras %d reintentos: %s", log_id, self.max_retries, exc)
        NotificationService.mark_failed(log_id)
