"""Chat con IA: sesión por usuario o IP, errores del microservicio y respuestas de respaldo."""
from unittest.mock import patch

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.music_discovery.views import ChatAPIView
from services.ai_client import AIServiceError
from tests.factories import UserFactory

REPLY = {"reply": "Te recomiendo Los Volcanes", "session_id": "x", "model_used": "gemini"}


class ChatDelegationTests(APITestCase):
    """El endpoint reenvía el mensaje al cliente de IA con la sesión correcta."""

    def setUp(self):
        self.url = reverse("chat")

    def test_authenticated_user_gets_ai_reply_with_user_session(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        history = [{"role": "user", "text": "Hola"}, {"role": "model", "text": "¡Hola!"}]
        with patch.object(ChatAPIView.ai_client, "chat", return_value=REPLY) as chat:
            response = self.client.post(self.url, {"message": "  rock en Pasto  ", "history": history}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, REPLY)
        chat.assert_called_once_with("rock en Pasto", f"user-{user.id}", history)

    def test_anonymous_user_session_is_based_on_ip(self):
        with patch.object(ChatAPIView.ai_client, "chat", return_value=REPLY) as chat:
            response = self.client.post(self.url, {"message": "Hola"}, format="json", REMOTE_ADDR="10.0.0.7")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        chat.assert_called_once_with("Hola", "anon-10.0.0.7", [])

    def test_message_of_exactly_500_characters_is_accepted(self):
        with patch.object(ChatAPIView.ai_client, "chat", return_value=REPLY):
            response = self.client.post(self.url, {"message": "a" * 500}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_too_long_message_never_reaches_the_ai(self):
        with patch.object(ChatAPIView.ai_client, "chat") as chat:
            response = self.client.post(self.url, {"message": "a" * 501}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        chat.assert_not_called()


class ChatErrorHandlingTests(APITestCase):
    """Cada tipo de fallo del cliente de IA se traduce en el código HTTP adecuado."""

    def setUp(self):
        self.url = reverse("chat")

    def post_with_error(self, error, message="Hola"):
        with patch.object(ChatAPIView.ai_client, "chat", side_effect=error):
            return self.client.post(self.url, {"message": message}, format="json")

    def test_ai_service_down_returns_503_with_fallback_reply(self):
        response = self.post_with_error(AIServiceError("caído"), message="Buenos días")
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertEqual(response.data["detail"], "Servicio de IA no disponible. Intenta más tarde.")
        self.assertIn("Bienvenido a Nariño Cultura", response.data["reply"])

    def test_value_error_returns_400_with_its_message(self):
        response = self.post_with_error(ValueError("El mensaje no puede estar vacío"))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data, {"detail": "El mensaje no puede estar vacío"})

    def test_unexpected_error_returns_500_without_leaking_details(self):
        response = self.post_with_error(RuntimeError("traza interna"))
        self.assertEqual(response.status_code, status.HTTP_500_INTERNAL_SERVER_ERROR)
        self.assertEqual(response.data, {"detail": "Error interno del servidor."})


class ChatFallbackResponseTests(APITestCase):
    """Respuestas de respaldo según el tema del mensaje."""

    def test_fallback_by_topic(self):
        cases = {
            "hola": "Bienvenido a Nariño Cultura",
            "Busco un ARTISTA": "comunidad vibrant de artistas",
            "algún músico local": "comunidad vibrant de artistas",
            "¿Hay concierto hoy?": "eventos culturales constantemente",
            "un evento cultural": "eventos culturales constantemente",
            "precio del envío": "Estoy aquí para ayudarte",
        }
        for message, expected in cases.items():
            with self.subTest(message=message):
                self.assertIn(expected, ChatAPIView._fallback_response(message))
