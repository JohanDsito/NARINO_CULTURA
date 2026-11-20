"""Cliente HTTP del microservicio de IA: peticiones, errores de red y respuestas inválidas."""
from unittest.mock import MagicMock, patch

import requests
from django.test import SimpleTestCase, override_settings

from services.ai_client import AIServiceClient, AIServiceError

AI_URL = "http://ai.test"


def ok_response(payload):
    response = MagicMock()
    response.raise_for_status.return_value = None
    response.json.return_value = payload
    return response


@override_settings(AI_SERVICE_URL=AI_URL)
class AIServiceClientRequestTests(SimpleTestCase):
    """Las peticiones llegan al endpoint correcto con el payload esperado."""

    def setUp(self):
        self.ai = AIServiceClient()

    def test_uses_configured_base_url_and_timeout(self):
        self.assertEqual(self.ai.base_url, AI_URL)
        self.assertEqual(self.ai.timeout, AIServiceClient.DEFAULT_TIMEOUT)

    @patch("services.ai_client.requests.post")
    def test_chat_posts_trimmed_message_and_empty_history(self, post):
        post.return_value = ok_response({"reply": "Hola", "session_id": "user-1", "model_used": "gemini"})
        result = self.ai.chat("  Hola  ", session_id="user-1")

        self.assertEqual(result["reply"], "Hola")
        post.assert_called_once_with(
            f"{AI_URL}/chat",
            json={"message": "Hola", "session_id": "user-1", "history": []},
            timeout=AIServiceClient.DEFAULT_TIMEOUT,
            headers={"Content-Type": "application/json"},
        )

    @patch("services.ai_client.requests.post")
    def test_enhance_artwork_sends_all_metadata(self, post):
        post.return_value = ok_response({"tags": ["andino"], "ai_description": "Obra colorida"})
        result = self.ai.enhance_artwork(
            "abc", "Carnaval", technique="Óleo", material="Lienzo",
            description="Desfile", dimensions="100x80", regenerate_description=True,
        )

        self.assertEqual(result, {"tags": ["andino"], "ai_description": "Obra colorida"})
        url = post.call_args.args[0]
        self.assertEqual(url, f"{AI_URL}/artworks/enhance")
        self.assertEqual(
            post.call_args.kwargs["json"],
            {
                "artwork_id": "abc", "title": "Carnaval", "technique": "Óleo", "material": "Lienzo",
                "description": "Desfile", "dimensions": "100x80", "regenerate_description": True,
            },
        )

    @patch("services.ai_client.requests.post")
    def test_recommend_music_posts_trimmed_query(self, post):
        post.return_value = ok_response({"genres": ["Rock"]})
        self.assertEqual(self.ai.recommend_music("  rock en Pasto "), {"genres": ["Rock"]})
        self.assertEqual(post.call_args.kwargs["json"], {"query": "rock en Pasto"})
        self.assertEqual(post.call_args.args[0], f"{AI_URL}/music/recommendations")

    @patch("services.ai_client.requests.post")
    def test_recommend_music_rejects_empty_query(self, post):
        for query in ("", "   "):
            with self.subTest(query=query), self.assertRaises(ValueError):
                self.ai.recommend_music(query)
        post.assert_not_called()

    @patch("services.ai_client.requests.get")
    def test_health_check_is_false_when_status_is_not_ok(self, get):
        get.return_value = ok_response({"status": "degraded"})
        self.assertFalse(self.ai.health_check())
        get.assert_called_once_with(f"{AI_URL}/health", timeout=AIServiceClient.DEFAULT_TIMEOUT)


@override_settings(AI_SERVICE_URL=AI_URL)
class AIServiceClientErrorTests(SimpleTestCase):
    """Todo fallo se convierte en AIServiceError con un mensaje claro."""

    def setUp(self):
        self.ai = AIServiceClient()

    def assert_ai_error(self, message, post_side_effect=None, post_return=None):
        with patch("services.ai_client.requests.post", side_effect=post_side_effect, return_value=post_return):
            with self.assertRaises(AIServiceError) as ctx:
                self.ai.chat("Hola", session_id="anon-1")
        self.assertIn(message, str(ctx.exception))

    def test_timeout(self):
        self.assert_ai_error("no responde a tiempo", post_side_effect=requests.exceptions.Timeout)

    def test_connection_error(self):
        self.assert_ai_error("No se puede conectar", post_side_effect=requests.exceptions.ConnectionError)

    def test_http_error_status(self):
        response = MagicMock()
        response.raise_for_status.side_effect = requests.exceptions.HTTPError("502 Bad Gateway")
        self.assert_ai_error("Error en AI Service: 502 Bad Gateway", post_return=response)

    def test_invalid_json(self):
        response = MagicMock()
        response.raise_for_status.return_value = None
        response.json.side_effect = ValueError("Expecting value")
        self.assert_ai_error("Respuesta inválida", post_return=response)

    def test_unsupported_http_method_is_reported_as_ai_error(self):
        """El ValueError del método no soportado lo captura el mismo manejador de JSON inválido."""
        with self.assertRaises(AIServiceError):
            self.ai._request("DELETE", "/chat")
