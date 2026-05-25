import logging

from django.core.cache import cache
from django.db import OperationalError, connection
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

logger = logging.getLogger("apps.system")


class HealthCheckAPIView(APIView):
    """Public endpoint to verify DB and cache connectivity."""

    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        checks = {}

        try:
            connection.ensure_connection()
            checks["database"] = "ok"
        except OperationalError:
            checks["database"] = "error"
            logger.error("Health check: database connection failed")

        try:
            cache.set("_health", "1", timeout=5)
            checks["cache"] = "ok" if cache.get("_health") else "degraded"
        except Exception:
            checks["cache"] = "error"
            logger.error("Health check: cache connection failed")

        all_ok = all(v == "ok" for v in checks.values())
        status_code = 200 if all_ok else 503
        return Response(
            {"status": "ok" if all_ok else "degraded", "checks": checks},
            status=status_code,
        )
