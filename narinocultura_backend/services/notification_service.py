from __future__ import annotations

from dataclasses import dataclass

import requests
from django.conf import settings

from apps.notifications.models import NotificationLog


@dataclass(frozen=True)
class NotificationResult:
    ok: bool
    status_code: int | None


class NotificationService:
    @staticmethod
    def send(notification_type: str, payload: dict, user=None) -> NotificationResult:
        webhook_url = getattr(settings, "N8N_WEBHOOK_URL", "")

        status_code = None
        ok = False
        if webhook_url:
            try:
                response = requests.post(
                    webhook_url,
                    json={"type": notification_type, "payload": payload},
                    timeout=10,
                )
                status_code = response.status_code
                ok = 200 <= response.status_code < 300
            except requests.RequestException:
                ok = False

        NotificationLog.objects.create(
            user=user if getattr(user, "is_authenticated", False) else None,
            notification_type=notification_type,
            payload=payload,
            status=NotificationLog.Status.ENVIADO if ok else NotificationLog.Status.FALLIDO,
        )
        return NotificationResult(ok=ok, status_code=status_code)

