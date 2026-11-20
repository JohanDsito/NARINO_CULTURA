"""AIService.enhance_artwork: etiquetas y descripción IA para obras de arte."""
from unittest.mock import MagicMock, patch

import requests
from django.test import TestCase, override_settings

from services.ai_service import AIService
from tests.factories import ArtworkFactory


def ai_response(payload=None, content=b"{}"):
    response = MagicMock()
    response.raise_for_status.return_value = None
    response.content = content
    response.json.return_value = payload or {}
    return response


class EnhanceArtworkTests(TestCase):
    def setUp(self):
        self.artwork = ArtworkFactory(
            title="Carnaval", technique="Óleo", dimensions="100x80", material="Lienzo",
            ai_tags=["previa"], ai_description="Descripción previa",
        )

    @override_settings(AI_SERVICE_URL="")
    @patch("services.ai_service.requests.post")
    def test_not_configured_raises_runtime_error(self, post):
        with self.assertRaisesMessage(RuntimeError, "Servicio de IA no configurado."):
            AIService.enhance_artwork(self.artwork)
        post.assert_not_called()

    @override_settings(AI_SERVICE_URL="http://ai.test/")
    @patch("services.ai_service.requests.post")
    def test_success_updates_tags_and_description(self, post):
        post.return_value = ai_response({"tags": ["andino", "color"], "ai_description": "Obra vibrante"})
        result = AIService.enhance_artwork(self.artwork, regenerate_description=True)

        self.assertEqual(result, {"ai_tags": ["andino", "color"], "ai_description": "Obra vibrante"})
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.ai_tags, ["andino", "color"])
        self.assertEqual(self.artwork.ai_description, "Obra vibrante")

        # La barra final de la URL base no se duplica
        self.assertEqual(post.call_args.args[0], "http://ai.test/artworks/enhance")
        payload = post.call_args.kwargs["json"]
        self.assertEqual(payload["artwork_id"], str(self.artwork.id))
        self.assertEqual(payload["title"], "Carnaval")
        self.assertEqual(payload["technique"], "Óleo")
        self.assertTrue(payload["regenerate_description"])
        self.assertEqual(post.call_args.kwargs["timeout"], 15)

    @override_settings(AI_SERVICE_URL="http://ai.test")
    @patch("services.ai_service.requests.post")
    def test_empty_response_keeps_previous_values(self, post):
        post.return_value = ai_response(content=b"")
        result = AIService.enhance_artwork(self.artwork)

        self.assertEqual(result, {"ai_tags": ["previa"], "ai_description": "Descripción previa"})
        post.return_value.json.assert_not_called()

    @override_settings(AI_SERVICE_URL="http://ai.test")
    @patch("services.ai_service.requests.post")
    def test_partial_response_only_updates_returned_fields(self, post):
        post.return_value = ai_response({"tags": ["nuevo"]})
        result = AIService.enhance_artwork(self.artwork)
        self.assertEqual(result, {"ai_tags": ["nuevo"], "ai_description": "Descripción previa"})

    @override_settings(AI_SERVICE_URL="http://ai.test")
    def test_network_and_http_errors_raise_runtime_error(self):
        failing = MagicMock()
        failing.raise_for_status.side_effect = requests.HTTPError("500")
        for kwargs in ({"side_effect": requests.ConnectionError("caído")}, {"return_value": failing}):
            with self.subTest(**{k: type(v).__name__ for k, v in kwargs.items()}):
                with patch("services.ai_service.requests.post", **kwargs):
                    with self.assertRaisesMessage(RuntimeError, "No fue posible contactar el microservicio de IA."):
                        AIService.enhance_artwork(self.artwork)
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.ai_description, "Descripción previa")
