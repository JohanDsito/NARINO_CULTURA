from celery import shared_task


@shared_task(ignore_result=True)
def send_event_reminders():
    """Recuerda los eventos de las próximas horas a sus inscritos. Se ejecuta cada 15 min vía Celery Beat."""
    from services.event_reminders import send_due_reminders

    return send_due_reminders()
