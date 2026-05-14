from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
from django.utils.html import strip_tags
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class EmailResult:
    ok: bool
    error_message: str | None = None


class EmailService:
    """Servicio para enviar emails desde el backend usando SMTP."""

    @staticmethod
    def send_verification_email(user_email: str, verification_token: str) -> EmailResult:
        """
        Envía un email de verificación de cuenta.
        
        Args:
            user_email: Email del usuario
            verification_token: Token de verificación generado
            
        Returns:
            EmailResult con el estado del envío
        """
        try:
            # Construir la URL de verificación
            verification_url = f"{settings.FRONTEND_URL}/verify-email?token={verification_token}"
            
            # Preparar el contexto
            context = {
                "verification_url": verification_url,
                "frontend_url": settings.FRONTEND_URL,
                "token": verification_token,
            }
            
            # Renderizar el template HTML
            html_message = render_to_string("emails/verify_email.html", context)
            
            # Crear version en texto plano
            text_message = strip_tags(html_message)
            
            # Crear el email
            subject = "Verifica tu correo en Nariño Cultura"
            email = EmailMultiAlternatives(
                subject=subject,
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user_email],
            )
            
            # Agregar versión HTML
            email.attach_alternative(html_message, "text/html")
            
            # Enviar el email
            email.send(fail_silently=False)
            
            logger.info(f"Email de verificación enviado a {user_email}")
            return EmailResult(ok=True)
            
        except Exception as e:
            error_message = f"Error al enviar email de verificación: {str(e)}"
            logger.error(error_message)
            return EmailResult(ok=False, error_message=error_message)

    @staticmethod
    def send_password_reset_email(user_email: str, reset_token: str) -> EmailResult:
        """
        Envía un email para resetear la contraseña.
        
        Args:
            user_email: Email del usuario
            reset_token: Token para resetear contraseña
            
        Returns:
            EmailResult con el estado del envío
        """
        try:
            # Construir la URL de reset
            reset_url = f"{settings.FRONTEND_URL}/reset-password?token={reset_token}"
            
            # Preparar el contexto
            context = {
                "reset_url": reset_url,
                "frontend_url": settings.FRONTEND_URL,
                "token": reset_token,
            }
            
            # Renderizar el template HTML
            html_message = render_to_string("emails/reset_password.html", context)
            
            # Crear version en texto plano
            text_message = strip_tags(html_message)
            
            # Crear el email
            subject = "Recupera tu contraseña en Nariño Cultura"
            email = EmailMultiAlternatives(
                subject=subject,
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user_email],
            )
            
            # Agregar versión HTML
            email.attach_alternative(html_message, "text/html")
            
            # Enviar el email
            email.send(fail_silently=False)
            
            logger.info(f"Email de reset de contraseña enviado a {user_email}")
            return EmailResult(ok=True)
            
        except Exception as e:
            error_message = f"Error al enviar email de reset: {str(e)}"
            logger.error(error_message)
            return EmailResult(ok=False, error_message=error_message)

    @staticmethod
    def send_welcome_email(user_email: str, user_name: str = "") -> EmailResult:
        """
        Envía un email de bienvenida.
        
        Args:
            user_email: Email del usuario
            user_name: Nombre del usuario
            
        Returns:
            EmailResult con el estado del envío
        """
        try:
            # Preparar el contexto
            context = {
                "user_name": user_name,
                "frontend_url": settings.FRONTEND_URL,
            }
            
            # Renderizar el template HTML
            html_message = render_to_string("emails/welcome.html", context)
            
            # Crear version en texto plano
            text_message = strip_tags(html_message)
            
            # Crear el email
            subject = "¡Bienvenido a Nariño Cultura!"
            email = EmailMultiAlternatives(
                subject=subject,
                body=text_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[user_email],
            )
            
            # Agregar versión HTML
            email.attach_alternative(html_message, "text/html")
            
            # Enviar el email
            email.send(fail_silently=False)
            
            logger.info(f"Email de bienvenida enviado a {user_email}")
            return EmailResult(ok=True)
            
        except Exception as e:
            error_message = f"Error al enviar email de bienvenida: {str(e)}"
            logger.error(error_message)
            return EmailResult(ok=False, error_message=error_message)
