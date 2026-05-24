import logging

logger = logging.getLogger("apps.system")


class ActivityLogMiddleware:
    """Logs mutating API requests asynchronously via Celery to avoid adding latency."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        if not request.path.startswith("/api/"):
            return response
        if request.method not in {"POST", "PUT", "PATCH", "DELETE"}:
            return response

        user = getattr(request, "user", None)
        user_id = (
            str(getattr(user, "id", None))
            if getattr(user, "is_authenticated", False)
            else None
        )

        try:
            from apps.system.tasks import create_activity_log

            create_activity_log.delay(
                user_id=user_id,
                action=f"{request.method} {request.path}",
                entity_type="http_request",
                entity_id=request.path,
                ip_address=self._get_ip(request),
                metadata={"status_code": getattr(response, "status_code", None)},
            )
        except Exception:
            # Celery might not be available in dev — fall back to sync write
            try:
                from apps.system.models import ActivityLog

                ActivityLog.objects.create(
                    user_id=user_id,
                    action=f"{request.method} {request.path}",
                    entity_type="http_request",
                    entity_id=request.path,
                    ip_address=self._get_ip(request),
                    metadata={"status_code": getattr(response, "status_code", None)},
                )
            except Exception as exc:
                logger.warning("ActivityLog fallback write failed: %s", exc)

        return response

    def _get_ip(self, request):
        xff = request.META.get("HTTP_X_FORWARDED_FOR")
        if xff:
            return xff.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR")
