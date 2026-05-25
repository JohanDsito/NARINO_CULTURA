from celery import shared_task


@shared_task(ignore_result=True, max_retries=2)
def create_activity_log(user_id, action, entity_type, entity_id, ip_address, metadata):
    """Persists an ActivityLog entry off the request/response cycle."""
    from apps.system.models import ActivityLog

    ActivityLog.objects.create(
        user_id=user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        ip_address=ip_address,
        metadata=metadata or {},
    )
