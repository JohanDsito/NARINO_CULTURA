from unittest.mock import MagicMock, patch

from django.core import mail
from django.template.loader import render_to_string
from django.test import SimpleTestCase, TestCase, override_settings

from services.email_service import EmailService, first_name, plain_text, with_display_name

FRONTEND = "https://narinocultura.test"
TEMPLATES = {
    "emails/verify_email.html": {"verification_url": f"{FRONTEND}/verify-email?token=abc", "verification_api_url": "", "token": "abc"},
    "emails/reset_password.html": {"reset_url": f"{FRONTEND}/reset-password?token=xyz", "token": "xyz"},
    "emails/admin_created_account.html": {"role_display": "Gestor cultural", "details": [("Correo", "g@test.com"), ("Contraseña temporal", "Temp-123")], "login_url": f"{FRONTEND}/login"},
    "emails/welcome.html": {"features": ["Descubre artistas"]},
    "emails/notifications/auction_opened.html": {"artwork_title": "Carnaval", "details": [("Obra", "Carnaval")], "auction_url": f"{FRONTEND}/auctions/1"},
    "emails/notifications/auction_rejected.html": {"artwork_title": "Carnaval"},
    "emails/notifications/auction_won.html": {"artwork_title": "Carnaval", "final_price": "$180.000 COP", "payment_due": "17 de diciembre", "details": [("Precio final", "$180.000 COP")], "orders_url": f"{FRONTEND}/orders"},
    "emails/notifications/auction_payment_expired.html": {"details": [("Valor de la orden", "$50.000 COP")]},
    "emails/notifications/payment_approved.html": {"amount": "$75.000 COP", "details": [("Valor pagado", "$75.000 COP")], "orders_url": f"{FRONTEND}/orders"},
    "emails/notifications/event_registration.html": {"event_title": "Noche andina", "details": [("Lugar", "Teatro Imperial")], "event_url": f"{FRONTEND}/events/1"},
}


def render(template, **extra):
    return render_to_string(template, {"frontend_url": FRONTEND, **TEMPLATES[template], **extra})


class EmailDesignTests(SimpleTestCase):
    """Los 10 correos comparten la identidad visual de la plataforma."""

    def test_every_email_uses_the_brand_layout(self):
        for template in TEMPLATES:
            with self.subTest(template=template):
                html = render(template, name="Ana")
                self.assertIn("#2D1B00", html)  # encabezado Volcán
                self.assertIn("#C9921A", html)  # línea Oro andino
                self.assertIn("Nariño Cultura", html)
                self.assertIn("Hola Ana,", html)
                self.assertIn(FRONTEND, html)

    def test_greeting_without_name_has_no_dangling_space(self):
        for template in TEMPLATES:
            with self.subTest(template=template):
                html = render(template, name="")
                self.assertIn("Hola,", html)
                self.assertNotIn("Hola ,", html)

    def test_buttons_point_to_the_right_place(self):
        self.assertIn(f'href="{FRONTEND}/verify-email?token=abc"', render("emails/verify_email.html"))
        self.assertIn("Pagar mi obra", render("emails/notifications/auction_won.html"))
        self.assertIn("Ver mis órdenes", render("emails/notifications/auction_won.html", payment_due=""))

    def test_details_box_hides_empty_values(self):
        html = render("emails/notifications/event_registration.html", details=[("Lugar", "Teatro Imperial"), ("Fecha", "")])
        self.assertIn("Teatro Imperial", html)
        self.assertNotIn("Fecha:", html)

    def test_plain_text_version_is_readable(self):
        text = plain_text(render("emails/notifications/payment_approved.html", name="Ana"))
        self.assertIn("Hola Ana,", text)
        self.assertIn("Valor pagado: $75.000 COP", text)
        self.assertNotIn("<", text)
        self.assertNotIn("&nbsp;", text)
        self.assertNotIn("\n\n\n", text)

    def test_first_name(self):
        self.assertEqual(first_name("Ana María Pérez"), "Ana")
        self.assertEqual(first_name(""), "")
        self.assertEqual(first_name(None), "")
        self.assertEqual(first_name("ana@test.com"), "")  # nunca saludar con el correo


@override_settings(EMAIL_FROM_NAME="Nariño Cultura")
class SenderNameTests(TestCase):
    def test_display_name_is_added(self):
        self.assertEqual(with_display_name("noreply@narinocultura.uk"), "Nariño Cultura <noreply@narinocultura.uk>")

    def test_existing_display_name_is_kept(self):
        self.assertEqual(with_display_name("Equipo <a@b.co>"), "Equipo <a@b.co>")

    @override_settings(RESEND_API_KEY="", DEFAULT_FROM_EMAIL="noreply@narinocultura.uk")
    def test_smtp_messages_show_the_platform_name(self):
        EmailService.send_welcome_email("ana@test.com", "Ana Pérez")
        (email,) = mail.outbox
        self.assertIn("noreply@narinocultura.uk", email.from_email)
        self.assertTrue(email.from_email.startswith("Nariño Cultura"))
        self.assertIn("Hola Ana,", email.alternatives[0][0])

    @override_settings(RESEND_API_KEY="re_test", RESEND_FROM_EMAIL="noreply@narinocultura.uk")
    @patch("services.email_service.requests.post")
    def test_resend_receives_the_display_name(self, post):
        post.return_value = MagicMock(status_code=200)
        EmailService.send_welcome_email("ana@test.com", "Ana")
        sender = post.call_args.kwargs["json"]["from"]
        self.assertEqual(sender, "Nariño Cultura <noreply@narinocultura.uk>")
