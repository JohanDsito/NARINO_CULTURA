"""Recordatorios de eventos (RF33, HU-B10).

Celery Beat ejecuta `send_due_reminders` cada 15 minutos. Cada inscripción a un evento publicado que empieza
dentro de las próximas `EVENT_REMINDER_HOURS` horas recibe **un solo** recordatorio, en la bandeja y por correo.
"""

from __future__ import annotations

import logging
from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.events.models import EventRegistration
from services.notification_service import NotificationService

logger = logging.getLogger("apps.events")


def due_registrations(now=None):
    """Inscripciones que deben recibir su recordatorio ahora."""
    now = now or timezone.now()
    horizon = now + timedelta(hours=settings.EVENT_REMINDER_HOURS)
    return EventRegistration.objects.filter(
        reminder_sent_at__isnull=True,
        event__is_published=True,
        event__start_date__gt=now,
        event__start_date__lte=horizon,
    ).select_related("event", "user")


def send_due_reminders(now=None) -> int:
    """Envía los recordatorios pendientes y devuelve cuántos se enviaron."""
    now = now or timezone.now()
    sent = 0
    for registration in due_registrations(now):
        with transaction.atomic():
            # Se "reclama" la inscripción con una actualización condicional: si otro worker ya la tomó,
            # no actualiza nada y no se envía. Así el recordatorio nunca sale dos veces.
            claimed = EventRegistration.objects.filter(pk=registration.pk, reminder_sent_at__isnull=True).update(
                reminder_sent_at=now
            )
            if not claimed:
                continue
            event, user = registration.event, registration.user
            NotificationService.send(
                "EVENT_REMINDER",
                {
                    "event_id": str(event.id),
                    "event_title": event.title,
                    "event_date": event.start_date.isoformat(),
                    "event_location": event.location or "",
                    "user_id": str(user.id),
                    "user_email": user.email,
                    "user_name": f"{user.first_name} {user.last_name}".strip() or user.email,
                },
                user=user,
            )
        sent += 1
    if sent:
        logger.info("Recordatorios de eventos enviados: %d", sent)
    return sent
