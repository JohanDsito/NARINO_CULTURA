from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
from django.utils.html import strip_tags
from dataclasses import dataclass
import logging
import requests

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class EmailResult:
    ok: bool
    error_message: str | None = None


class EmailService:
    """Servicio para enviar emails desde el backend."""

    @staticmethod
    def _send_via_resend(subject: str, user_email: str, html_message: str, text_message: str) -> EmailResult:
        if not getattr(settings, "RESEND_API_KEY", ""):
            return EmailResult(ok=False, error_message="Resend API key no configurada")

        try:
            payload = {
                "from": settings.DEFAULT_FROM_EMAIL,
                "to": [user_email],
                "subject": subject,
                "html": html_message,
                "text": text_message,
            }
            headers = {
                "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                "Content-Type": "application/json",
            }
            response = requests.post("https://api.resend.com/emails", json=payload, headers=headers, timeout=10)
            if response.status_code >= 200 and response.status_code < 300:
                return EmailResult(ok=True)
            return EmailResult(
                ok=False,
                error_message=f"Resend API error {response.status_code}: {response.text}",
            )
        except requests.RequestException as e:
            return EmailResult(ok=False, error_message=f"Error de red con Resend: {str(e)}")
        except Exception as e:
            return EmailResult(ok=False, error_message=f"Error inesperado con Resend: {str(e)}")

    @staticmethod
    def _send_via_smtp(subject: str, user_email: str, html_message: str, text_message: str) -> EmailResult:
        try:
            email = EmailMultiAlternatives(
                subject=subject,
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user_email],
            )
            email.attach_alternative(html_message, "text/html")
            email.send(fail_silently=False)
            return EmailResult(ok=True)
        except Exception as e:
            return EmailResult(ok=False, error_message=str(e))

    @staticmethod
    def _send_email(subject: str, user_email: str, html_message: str, text_message: str) -> EmailResult:
        if getattr(settings, "RESEND_API_KEY", ""):
            result = EmailService._send_via_resend(subject, user_email, html_message, text_message)
            if result.ok:
                logger.info(f"Email enviado a {user_email} vía Resend")
                return result
            logger.warning(f"Resend falló, intentando SMTP: {result.error_message}")
        result = EmailService._send_via_smtp(subject, user_email, html_message, text_message)
        if result.ok:
            logger.info(f"Email enviado a {user_email} vía SMTP")
        else:
            logger.error(f"Error SMTP: {result.error_message}")
        return result

    @staticmethod
    def send_verification_email(user_email: str, verification_token: str) -> EmailResult:
        verification_url = f"{settings.FRONTEND_URL}/verify-email?token={verification_token}"
        context = {
            "verification_url": verification_url,
            "frontend_url": settings.FRONTEND_URL,
            "token": verification_token,
        }
        html_message = render_to_string("emails/verify_email.html", context)
        text_message = strip_tags(html_message)
        subject = "Verifica tu correo en Nariño Cultura"
        result = EmailService._send_email(subject, user_email, html_message, text_message)
        if not result.ok:
            error_message = f"Error al enviar email de verificación: {result.error_message}"
            logger.error(error_message)
            return EmailResult(ok=False, error_message=error_message)
        return EmailResult(ok=True)

    @staticmethod
    def send_password_reset_email(user_email: str, reset_token: str) -> EmailResult:
        reset_url = f"{settings.FRONTEND_URL}/reset-password?token={reset_token}"
        context = {
            "reset_url": reset_url,
            "frontend_url": settings.FRONTEND_URL,
            "token": reset_token,
        }
        html_message = render_to_string("emails/reset_password.html", context)
        text_message = strip_tags(html_message)
        subject = "Recupera tu contraseña en Nariño Cultura"
        result = EmailService._send_email(subject, user_email, html_message, text_message)
        if not result.ok:
            error_message = f"Error al enviar email de reset: {result.error_message}"
            logger.error(error_message)
            return EmailResult(ok=False, error_message=error_message)
        return EmailResult(ok=True)

    @staticmethod
    def send_welcome_email(user_email: str, user_name: str = "") -> EmailResult:
        context = {
            "user_name": user_name,
            "frontend_url": settings.FRONTEND_URL,
        }
        html_message = render_to_string("emails/welcome.html", context)
        text_message = strip_tags(html_message)
        subject = "¡Bienvenido a Nariño Cultura!"
        result = EmailService._send_email(subject, user_email, html_message, text_message)
        if not result.ok:
            error_message = f"Error al enviar email de bienvenida: {result.error_message}"
            logger.error(error_message)
            return EmailResult(ok=False, error_message=error_message)
        return EmailResult(ok=True)
