"""Chat con IA: sesión por usuario o IP, validaciones y respuestas de respaldo por reglas."""
from unittest.mock import patch

from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from services import ai_rules
from tests.factories import UserFactory

REPLY = {"reply": "Te recomiendo Los Volcanes", "session_id": "x", "model_used": "gemini"}
CHAT = "apps.music_discovery.views.AIService.chat"


class ChatDelegationTests(APITestCase):
    """El endpoint pasa el mensaje a la capa de IA con la sesión correcta."""

    def setUp(self):
        self.url = reverse("chat")

    def test_authenticated_user_gets_ai_reply_with_user_session(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        history = [{"role": "user", "text": "Hola"}, {"role": "model", "text": "¡Hola!"}]
        with patch(CHAT, return_value=REPLY) as chat:
            response = self.client.post(self.url, {"message": "  rock en Pasto  ", "history": history}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, REPLY)
        chat.assert_called_once_with("rock en Pasto", session_id=f"user-{user.id}", history=history)

    def test_anonymous_user_session_is_based_on_ip(self):
        with patch(CHAT, return_value=REPLY) as chat:
            response = self.client.post(self.url, {"message": "Hola"}, format="json", REMOTE_ADDR="10.0.0.7")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        chat.assert_called_once_with("Hola", session_id="anon-10.0.0.7", history=None)

    def test_message_of_exactly_500_characters_is_accepted(self):
        with patch(CHAT, return_value=REPLY):
            response = self.client.post(self.url, {"message": "a" * 500}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_too_long_or_blank_messages_never_reach_the_ai(self):
        with patch(CHAT) as chat:
            for message in ("a" * 501, "   "):
                response = self.client.post(self.url, {"message": message}, format="json")
                self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        chat.assert_not_called()


class ChatWithoutProvidersTests(APITestCase):
    """Sin llaves de IA (settings de test) el chat responde igual, con reglas: nunca 503."""

    def test_rule_based_reply(self):
        response = self.client.post(reverse("chat"), {"message": "Buenos días"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["model_used"], "rule-based")
        self.assertIn("Bienvenido a Nariño Cultura", response.data["reply"])

    def test_rule_reply_by_topic(self):
        cases = {
            "hola": "Bienvenido a Nariño Cultura",
            "Busco un ARTISTA": "catálogo",
            "algún músico local": "Músicos",
            "¿Hay festival hoy?": "Eventos",
            "¿Cómo pago mi pedido?": "Wompi",
            "quiero pujar": "Subastas",
            "precio del envío": "Wompi",
            "qwerty": "Puedo ayudarte",
        }
        for message, expected in cases.items():
            with self.subTest(message=message):
                self.assertIn(expected, ai_rules.chat_reply(message))


class RuleBasedArtworkTextTests(TestCase):
    """Descripción y respuesta de cortesía por reglas (cuando no hay proveedor de IA)."""

    def test_thanks_reply(self):
        self.assertIn("Con gusto", ai_rules.chat_reply("Muchas gracias"))

    def test_description_with_only_material_technique_or_dimensions(self):
        base = {"title": "", "description": "", "technique": "", "material": "", "dimensions": ""}
        self.assertEqual(
            ai_rules.artwork_description(**{**base, "material": "Lienzo"}).split(". ")[0],
            "Está elaborada en lienzo",
        )
        self.assertIn("técnica de óleo.", ai_rules.artwork_description(**{**base, "technique": "Óleo"}))
        text = ai_rules.artwork_description(**{**base, "dimensions": "50x70 cm", "description": "Paisaje"})
        self.assertIn("Sus dimensiones son 50x70 cm.", text)
        self.assertTrue(text.endswith("Paisaje"))
        self.assertNotIn("«", text)  # sin título no se menciona la obra por nombre
