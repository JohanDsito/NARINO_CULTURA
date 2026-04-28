from __future__ import annotations

from dataclasses import dataclass

import requests
from django.conf import settings
from django.core.mail import send_mail

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

        if notification_type == "EMAIL_VERIFICATION":
            # Enviar email directamente
            email = payload.get("email")
            token = payload.get("token")
            if email and token:
                subject = "Verifica tu cuenta en Nariño Cultura"
                message = f"""
                ¡Hola!

                Gracias por registrarte en Nariño Cultura. Para verificar tu cuenta, haz clic en el siguiente enlace:

                http://tu-dominio.com/verify-email?token={token}

                Si no solicitaste esta verificación, ignora este mensaje.

                Saludos,
                El equipo de Nariño Cultura
                """
                try:
                    send_mail(
                        subject,
                        message,
                        settings.DEFAULT_FROM_EMAIL,
                        [email],
                        fail_silently=False,
                    )
                    ok = True
                    status_code = 200
                except Exception as e:
                    print(f"Error enviando email: {e}")
                    ok = False
        elif webhook_url:
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

