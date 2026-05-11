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
    def _build_payload(notification_type: str, payload: dict) -> dict:
        enriched_payload = dict(payload)
        frontend_base_url = getattr(settings, "FRONTEND_BASE_URL", "").rstrip("/")
        api_base_url = getattr(settings, "API_BASE_URL", "").rstrip("/")

        if notification_type == "EMAIL_VERIFICATION":
            token = payload.get("token")
            if token:
                if frontend_base_url:
                    enriched_payload["verification_url"] = f"{frontend_base_url}/verify-email?token={token}"
                if api_base_url:
                    enriched_payload["verification_api_url"] = f"{api_base_url}/api/v1/auth/verify-email/"

        if notification_type == "PASSWORD_RESET":
            token = payload.get("token")
            if token and frontend_base_url:
                enriched_payload["reset_url"] = f"{frontend_base_url}/reset-password?token={token}"

        return enriched_payload

    @staticmethod
    def send(notification_type: str, payload: dict, user=None) -> NotificationResult:
        webhook_url = getattr(settings, "N8N_WEBHOOK_URL", "")
        normalized_payload = NotificationService._build_payload(notification_type, payload)

        status_code = None
        ok = False
        if webhook_url:
            try:
                response = requests.post(
                    webhook_url,
                    json={
                        "type": notification_type,
                        "payload": normalized_payload,
                        "user": {
                            "id": str(user.id),
                            "email": user.email,
                            "first_name": user.first_name,
                            "last_name": user.last_name,
                        }
                        if user
                        else None,
                    },
                    timeout=10,
                )
                status_code = response.status_code
                ok = 200 <= response.status_code < 300
            except requests.RequestException:
                ok = False

        NotificationLog.objects.create(
            user=user if getattr(user, "is_authenticated", False) else None,
            notification_type=notification_type,
            payload=normalized_payload,
            status=NotificationLog.Status.ENVIADO if ok else NotificationLog.Status.FALLIDO,
        )
        return NotificationResult(ok=ok, status_code=status_code)

