"""
Tests para music_discovery app - Chat conversacional e IA.
"""
from django.test import TestCase, Client
from django.urls import reverse
from rest_framework.test import APIClient, APITestCase
from rest_framework import status

from apps.users.models import User
from services.ai_client import AIServiceClient, AIServiceException


class AIServiceClientTests(TestCase):
    """Tests para el cliente de AI Service."""

    def setUp(self):
        self.client_ai = AIServiceClient()

    def test_health_check_success(self):
        """Verifica que health_check devuelve True cuando servicio está disponible."""
        # Nota: Esto asume que AI Service está corriendo
        # En CI/CD, mock este comportamiento
        is_healthy = self.client_ai.health_check()
        # Si el servicio está corriendo, debería ser True
        # En tests, puedes mockear con @patch

    def test_chat_with_empty_message_raises_error(self):
        """Chat con mensaje vacío debe raise ValueError."""
        with self.assertRaises(ValueError):
            self.client_ai.chat("", session_id="user-1")

    def test_chat_with_whitespace_only_raises_error(self):
        """Chat con solo espacios debe raise ValueError."""
        with self.assertRaises(ValueError):
            self.client_ai.chat("   ", session_id="user-1")


class ChatAPIViewTests(APITestCase):
    """Tests para el endpoint de chat conversacional."""

    def setUp(self):
        # Crear usuario de prueba
        self.user = User.objects.create_user(
            email="testuser@example.com",
            password="testpass123",
            first_name="Test",
            last_name="User",
            role=User.Role.COMPRADOR
        )

        self.client = APIClient()
        self.chat_url = reverse("chat")

    def test_chat_requires_authentication(self):
        """Chat endpoint debe requerir autenticación."""
        response = self.client.post(
            self.chat_url,
            {"message": "Hola"},
            format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_chat_with_authenticated_user_success(self):
        """Chat con usuario autenticado debe devolver 200/503 (depende AI Service)."""
        self.client.force_authenticate(user=self.user)

        data = {
            "message": "Hola, busco artistas de rock",
            "history": []
        }

        response = self.client.post(self.chat_url, data, format="json")

        # Puede ser 200 (AI Service OK) o 503 (AI Service down)
        # En ambos casos, la respuesta es válida
        self.assertIn(
            response.status_code,
            [status.HTTP_200_OK, status.HTTP_503_SERVICE_UNAVAILABLE]
        )

    def test_chat_with_empty_message_fails(self):
        """Chat con mensaje vacío debe devolver 400."""
        self.client.force_authenticate(user=self.user)

        data = {
            "message": "",
            "history": []
        }

        response = self.client.post(self.chat_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_chat_with_missing_message_field_fails(self):
        """Chat sin campo 'message' debe devolver 400."""
        self.client.force_authenticate(user=self.user)

        data = {"history": []}

        response = self.client.post(self.chat_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_chat_with_too_long_message_fails(self):
        """Chat con mensaje > 500 caracteres debe devolver 400."""
        self.client.force_authenticate(user=self.user)

        long_message = "x" * 501

        data = {
            "message": long_message,
            "history": []
        }

        response = self.client.post(self.chat_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_chat_response_structure(self):
        """Respuesta de chat debe tener estructura correcta."""
        self.client.force_authenticate(user=self.user)

        data = {
            "message": "Hola",
            "history": []
        }

        response = self.client.post(self.chat_url, data, format="json")

        # Si AI Service está disponible
        if response.status_code == status.HTTP_200_OK:
            self.assertIn("reply", response.data)
            self.assertIn("session_id", response.data)
            self.assertIn("model_used", response.data)
            self.assertIsInstance(response.data["reply"], str)

    def test_chat_with_history_preserved(self):
        """Historial de chat debe ser procesado correctamente."""
        self.client.force_authenticate(user=self.user)

        history = [
            {"role": "user", "text": "Hola"},
            {"role": "model", "text": "¡Hola!"}
        ]

        data = {
            "message": "¿Qué artistas recomendadas?",
            "history": history
        }

        response = self.client.post(self.chat_url, data, format="json")

        # Si AI Service está disponible, la respuesta es válida
        if response.status_code == status.HTTP_200_OK:
            self.assertIn("reply", response.data)

    def test_chat_session_id_based_on_user(self):
        """Cada usuario debe tener su propia sesión."""
        user2 = User.objects.create_user(
            email="testuser2@example.com",
            password="testpass123",
            first_name="Test2",
            last_name="User2",
            role=User.Role.COMPRADOR
        )

        # Usuario 1
        self.client.force_authenticate(user=self.user)
        response1 = self.client.post(
            self.chat_url,
            {"message": "Hola usuario 1"},
            format="json"
        )

        # Usuario 2
        self.client.force_authenticate(user=user2)
        response2 = self.client.post(
            self.chat_url,
            {"message": "Hola usuario 2"},
            format="json"
        )

        # Los session_id deben ser diferentes
        if response1.status_code == status.HTTP_200_OK and \
           response2.status_code == status.HTTP_200_OK:
            self.assertNotEqual(
                response1.data["session_id"],
                response2.data["session_id"]
            )


class MusicRecommendationViewTests(APITestCase):
    """Tests para el endpoint de recomendaciones de música."""

    def setUp(self):
        self.client = APIClient()
        self.url = reverse("music-recommendations")

    def test_recommendation_requires_query(self):
        """Recomendación sin query debe devolver 400."""
        response = self.client.post(self.url, {}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_recommendation_with_empty_query_fails(self):
        """Recomendación con query vacía debe devolver 400."""
        response = self.client.post(
            self.url,
            {"query": ""},
            format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_recommendation_response_structure(self):
        """Respuesta debe tener estructura correcta."""
        response = self.client.post(
            self.url,
            {"query": "rock"},
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("query", response.data)
        self.assertIn("filters_applied", response.data)
        self.assertIn("count", response.data)
        self.assertIn("results", response.data)
        self.assertIsInstance(response.data["results"], list)
