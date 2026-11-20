"""EmailService: Resend como canal principal, SMTP de respaldo y correos de autenticación."""
from unittest.mock import MagicMock, patch

import requests
from django.core import mail
from django.test import SimpleTestCase, override_settings

from services.email_service import EmailResult, EmailService

FRONTEND = "https://narinocultura.test"
RESEND = {"RESEND_API_KEY": "re_test", "RESEND_FROM_EMAIL": "noreply@narinocultura.test"}


def resend_response(status_code, text=""):
    response = MagicMock()
    response.status_code = status_code
    response.text = text
    return response


class BuildUrlTests(SimpleTestCase):
    def test_normalizes_slashes_and_encodes_query(self):
        url = EmailService._build_url("https://web.test/", "verify-email", {"token": "a b&c"})
        self.assertEqual(url, "https://web.test/verify-email?token=a+b%26c")

    def test_without_query_params(self):
        self.assertEqual(EmailService._build_url("https://web.test", "/login"), "https://web.test/login")
        self.assertEqual(EmailService._build_url(None, "/login"), "/login")


class ResendTests(SimpleTestCase):
    """Envío por la API de Resend."""

    def send(self):
        return EmailService._send_via_resend("Asunto", "ana@test.com", "<p>Hola</p>", "Hola")

    @override_settings(RESEND_API_KEY="")
    def test_missing_api_key(self):
        self.assertEqual(self.send(), EmailResult(ok=False, error_message="Resend API key no configurada"))

    @override_settings(RESEND_API_KEY="re_test", RESEND_FROM_EMAIL="")
    def test_missing_from_email(self):
        self.assertEqual(self.send(), EmailResult(ok=False, error_message="Resend FROM_EMAIL no configurado"))

    @override_settings(**RESEND)
    @patch("services.email_service.requests.post", return_value=resend_response(202))
    def test_success_sends_authenticated_json(self, post):
        self.assertEqual(self.send(), EmailResult(ok=True))
        kwargs = post.call_args.kwargs
        self.assertEqual(post.call_args.args[0], "https://api.resend.com/emails")
        self.assertEqual(kwargs["headers"]["Authorization"], "Bearer re_test")
        self.assertEqual(kwargs["json"]["to"], ["ana@test.com"])
        self.assertEqual(kwargs["json"]["text"], "Hola")
        self.assertEqual(kwargs["timeout"], 10)

    @override_settings(**RESEND)
    @patch("services.email_service.requests.post", return_value=resend_response(422, "dominio no verificado"))
    def test_error_status_is_reported(self, _post):
        result = self.send()
        self.assertFalse(result.ok)
        self.assertEqual(result.error_message, "Resend API error 422: dominio no verificado")

    @override_settings(**RESEND)
    @patch("services.email_service.requests.post", side_effect=requests.ConnectionError("sin red"))
    def test_network_error_is_reported(self, _post):
        self.assertEqual(self.send().error_message, "Error de red con Resend: sin red")

    @override_settings(**RESEND)
    @patch("services.email_service.requests.post", side_effect=KeyError("raro"))
    def test_unexpected_error_is_reported(self, _post):
        self.assertTrue(self.send().error_message.startswith("Error inesperado con Resend:"))


class SendEmailFallbackTests(SimpleTestCase):
    """Resend primero; si falla o no está configurado, SMTP."""

    def send(self):
        return EmailService._send_email("Asunto", "ana@test.com", "<p>Hola</p>", "Hola")

    @override_settings(**RESEND)
    @patch("services.email_service.requests.post", return_value=resend_response(200))
    def test_resend_success_skips_smtp(self, _post):
        self.assertTrue(self.send().ok)
        self.assertEqual(len(mail.outbox), 0)

    @override_settings(**RESEND)
    @patch("services.email_service.requests.post", return_value=resend_response(500, "caído"))
    def test_resend_failure_falls_back_to_smtp(self, _post):
        self.assertTrue(self.send().ok)
        self.assertEqual(len(mail.outbox), 1)
        message = mail.outbox[0]
        self.assertEqual(message.to, ["ana@test.com"])
        self.assertEqual(message.body, "Hola")
        self.assertEqual(message.alternatives[0][1], "text/html")

    @override_settings(RESEND_API_KEY="")
    def test_without_resend_uses_smtp(self):
        self.assertTrue(self.send().ok)
        self.assertEqual(len(mail.outbox), 1)

    @override_settings(RESEND_API_KEY="")
    @patch("services.email_service.EmailMultiAlternatives.send", side_effect=OSError("SMTP caído"))
    def test_smtp_failure_is_reported(self, _send):
        self.assertEqual(self.send(), EmailResult(ok=False, error_message="SMTP caído"))


@override_settings(FRONTEND_URL=FRONTEND, RESEND_API_KEY="")
class AuthEmailTests(SimpleTestCase):
    """Correos de verificación, recuperación, cuenta creada y bienvenida."""

    def last_email(self):
        self.assertEqual(len(mail.outbox), 1)
        message = mail.outbox[0]
        return message, message.alternatives[0][0]

    @override_settings(API_BASE_URL="https://api.test")
    def test_verification_email_includes_frontend_and_api_links(self):
        result = EmailService.send_verification_email("ana@test.com", "tok123", "Ana Pérez")
        self.assertTrue(result.ok)
        message, html = self.last_email()
        self.assertEqual(message.subject, "Verifica tu correo en Nariño Cultura")
        self.assertIn(f"{FRONTEND}/verify-email?token=tok123", html)
        self.assertIn("Hola Ana,", html)

    @override_settings(API_BASE_URL="")
    @patch("services.email_service.EmailService.send_template", return_value=EmailResult(ok=True))
    def test_verification_email_without_api_base_url(self, send_template):
        EmailService.send_verification_email("ana@test.com", "tok123")
        context = send_template.call_args.kwargs["context"]
        self.assertEqual(context["verification_api_url"], "")
        self.assertEqual(context["name"], "")

    @override_settings(API_BASE_URL="https://api.test/")
    @patch("services.email_service.EmailService.send_template", return_value=EmailResult(ok=True))
    def test_verification_api_url_points_to_backend(self, send_template):
        EmailService.send_verification_email("ana@test.com", "tok123")
        context = send_template.call_args.kwargs["context"]
        self.assertEqual(context["verification_api_url"], "https://api.test/api/v1/auth/verify-email/?token=tok123")

    def test_password_reset_email(self):
        self.assertTrue(EmailService.send_password_reset_email("ana@test.com", "rst", "Ana").ok)
        message, html = self.last_email()
        self.assertEqual(message.subject, "Recupera tu contraseña en Nariño Cultura")
        self.assertIn(f"{FRONTEND}/reset-password?token=rst", html)

    def test_admin_created_account_email(self):
        result = EmailService.send_admin_created_account_email("g@test.com", "Gloria Díaz", "Temp-123", "Gestor cultural")
        self.assertTrue(result.ok)
        message, html = self.last_email()
        self.assertEqual(message.subject, "Tu cuenta en Nariño Cultura está lista")
        self.assertIn("Temp-123", html)
        self.assertIn(f"{FRONTEND}/login", html)

    def test_welcome_email(self):
        self.assertTrue(EmailService.send_welcome_email("ana@test.com", "Ana").ok)
        message, html = self.last_email()
        self.assertEqual(message.subject, "¡Bienvenido a Nariño Cultura!")
        self.assertIn("Participa en subastas en tiempo real", html)

    @patch("services.email_service.EmailMultiAlternatives.send", side_effect=OSError("SMTP caído"))
    def test_failure_message_names_the_email_kind(self, _send):
        with self.assertLogs("services.email_service", level="ERROR"):
            result = EmailService.send_password_reset_email("ana@test.com", "rst")
        self.assertEqual(result, EmailResult(ok=False, error_message="Error al enviar email de reset: SMTP caído"))
