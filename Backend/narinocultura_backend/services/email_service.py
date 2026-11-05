import html
import logging
import re
from dataclasses import dataclass
from email.utils import parseaddr
from urllib.parse import urlencode

import requests
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils.html import strip_tags

logger = logging.getLogger(__name__)


def first_name(full_name: str | None) -> str:
    """Saludo cercano: solo el primer nombre ("Ana Pérez" -> "Ana")."""
    return (full_name or "").strip().split(" ")[0] if full_name and "@" not in full_name else ""


def plain_text(html_message: str) -> str:
    """Versión en texto plano legible: sin etiquetas, sin entidades y sin bloques de espacios."""
    text = re.sub(r"(?is)<(style|title)[^>]*>.*?</\1>", "", html_message)
    text = re.sub(r"(?i)<br\s*/?>|</p>|</tr>|</h1>", "\n", text)
    text = html.unescape(strip_tags(text))
    lines = [line.strip() for line in text.splitlines()]
    return re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip()


def with_display_name(address: str) -> str:
    """Agrega el nombre visible del remitente: "Nariño Cultura <noreply@...>"."""
    name, email = parseaddr(address or "")
    if not email or name:
        return address
    # Sin codificar: Resend (JSON en UTF-8) y Django (al armar la cabecera) codifican la "ñ" por su cuenta
    return f"{getattr(settings, 'EMAIL_FROM_NAME', 'Nariño Cultura')} <{email}>"


@dataclass(frozen=True)
class EmailResult:
    ok: bool
    error_message: str | None = None


class EmailService:
    """Servicio para enviar emails desde el backend."""

    @staticmethod
    def _build_url(base_url: str, path: str, query_params: dict[str, str] | None = None) -> str:
        normalized_base = (base_url or "").rstrip("/")
        normalized_path = "/" + path.lstrip("/")
        url = f"{normalized_base}{normalized_path}"
        if query_params:
            url = f"{url}?{urlencode(query_params)}"
        return url

    @staticmethod
    def _send_via_resend(subject: str, user_email: str, html_message: str, text_message: str) -> EmailResult:
        resend_api_key = getattr(settings, "RESEND_API_KEY", "")
        resend_from_email = getattr(settings, "RESEND_FROM_EMAIL", "")

        if not resend_api_key:
            return EmailResult(ok=False, error_message="Resend API key no configurada")
        if not resend_from_email:
            return EmailResult(ok=False, error_message="Resend FROM_EMAIL no configurado")

        try:
            payload = {
                "from": with_display_name(resend_from_email),
                "to": [user_email],
                "subject": subject,
                "html": html_message,
                "text": text_message,
            }
            headers = {
                "Authorization": f"Bearer {resend_api_key}",
                "Content-Type": "application/json",
            }
            response = requests.post(
                "https://api.resend.com/emails",
                json=payload,
                headers=headers,
                timeout=10,
            )
            if 200 <= response.status_code < 300:
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
                from_email=with_display_name(settings.DEFAULT_FROM_EMAIL),
                to=[user_email],
            )
            email.attach_alternative(html_message, "text/html")
            email.send(fail_silently=False)
            return EmailResult(ok=True)
        except Exception as e:
            return EmailResult(ok=False, error_message=str(e))

    @staticmethod
    def _send_email(subject: str, user_email: str, html_message: str, text_message: str) -> EmailResult:
        # Intentar Resend primero
        resend_api_key = getattr(settings, "RESEND_API_KEY", "")
        if resend_api_key:
            result = EmailService._send_via_resend(subject, user_email, html_message, text_message)
            if result.ok:
                logger.info(f"Email enviado a {user_email} vía Resend")
                return result
            logger.warning(f"Resend falló, intentando SMTP: {result.error_message}")

        # Fallback a SMTP
        result = EmailService._send_via_smtp(subject, user_email, html_message, text_message)
        if result.ok:
            logger.info(f"Email enviado a {user_email} vía SMTP")
        else:
            logger.error(f"Error SMTP: {result.error_message}")
        return result

    @staticmethod
    def send_template(*, to: str, subject: str, template: str, context: dict) -> EmailResult:
        """Renderiza una plantilla de correo y la envía (Resend y, como respaldo, SMTP)."""
        html_message = render_to_string(template, {"frontend_url": settings.FRONTEND_URL, **context})
        return EmailService._send_email(subject, to, html_message, plain_text(html_message))

    @staticmethod
    def _send_auth_email(*, to: str, subject: str, template: str, context: dict, error_label: str) -> EmailResult:
        result = EmailService.send_template(to=to, subject=subject, template=template, context=context)
        if not result.ok:
            error_message = f"Error al enviar email de {error_label}: {result.error_message}"
            logger.error(error_message)
            return EmailResult(ok=False, error_message=error_message)
        return EmailResult(ok=True)

    @staticmethod
    def send_verification_email(user_email: str, verification_token: str, user_name: str = "") -> EmailResult:
        frontend_verification_url = EmailService._build_url(
            settings.FRONTEND_URL,
            "/verify-email",
            {"token": verification_token},
        )
        api_base_url = getattr(settings, "API_BASE_URL", "")
        verification_api_url = (
            EmailService._build_url(
                api_base_url,
                "/api/v1/auth/verify-email/",
                {"token": verification_token},
            )
            if api_base_url
            else ""
        )
        return EmailService._send_auth_email(
            to=user_email,
            subject="Verifica tu correo en Nariño Cultura",
            template="emails/verify_email.html",
            context={
                "name": first_name(user_name),
                "verification_url": frontend_verification_url,
                "verification_api_url": verification_api_url,
                "token": verification_token,
            },
            error_label="verificación",
        )

    @staticmethod
    def send_password_reset_email(user_email: str, reset_token: str, user_name: str = "") -> EmailResult:
        reset_url = EmailService._build_url(
            settings.FRONTEND_URL,
            "/reset-password",
            {"token": reset_token},
        )
        return EmailService._send_auth_email(
            to=user_email,
            subject="Recupera tu contraseña en Nariño Cultura",
            template="emails/reset_password.html",
            context={"name": first_name(user_name), "reset_url": reset_url, "token": reset_token},
            error_label="reset",
        )

    @staticmethod
    def send_admin_created_account_email(
        user_email: str, user_name: str, temp_password: str, role_display: str
    ) -> EmailResult:
        return EmailService._send_auth_email(
            to=user_email,
            subject="Tu cuenta en Nariño Cultura está lista",
            template="emails/admin_created_account.html",
            context={
                "name": first_name(user_name),
                "role_display": role_display,
                "details": [("Correo", user_email), ("Contraseña temporal", temp_password)],
                "login_url": EmailService._build_url(settings.FRONTEND_URL, "/login"),
            },
            error_label="cuenta creada",
        )

    @staticmethod
    def send_welcome_email(user_email: str, user_name: str = "") -> EmailResult:
        return EmailService._send_auth_email(
            to=user_email,
            subject="¡Bienvenido a Nariño Cultura!",
            template="emails/welcome.html",
            context={
                "name": first_name(user_name),
                "features": [
                    "Descubre artistas, músicos y obras de la región",
                    "Compra obras originales con pago seguro",
                    "Participa en subastas en tiempo real",
                    "Inscríbete en eventos de la agenda cultural",
                ],
            },
            error_label="bienvenida",
        )
