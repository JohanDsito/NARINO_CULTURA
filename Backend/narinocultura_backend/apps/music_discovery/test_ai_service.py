"""Capa de IA (services/llm.py y services/ai_service.py) con Gemini y Groq simulados."""
from datetime import timedelta
from unittest.mock import patch

import requests
from django.core.cache import cache
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.artworks.models import Artwork
from services import llm
from services.ai_service import AIService, _fetch_image
from tests import llm_fakes
from tests.factories import (
    ArtworkFactory,
    EventFactory,
    MusicGenreFactory,
    MusicianProfileFactory,
)

LOCMEM = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache", "LOCATION": "ai-tests"}}


@override_settings(GEMINI_API_KEY="gemini-test", GROQ_API_KEY="groq-test")
class DefaultProviderOrderTests(TestCase):
    """Por defecto el texto va primero a Groq (más rápido y estable) y las imágenes a Gemini."""

    @patch("services.llm._session.post")
    def test_text_goes_to_groq_first_with_short_reasoning(self, post):
        post.return_value = llm_fakes.groq("Hola desde Groq")
        result = llm.generate("Hola")
        self.assertEqual(result.provider, "groq")
        body = post.call_args.kwargs["json"]
        self.assertEqual((body["model"], body["reasoning_effort"]), ("openai/gpt-oss-120b", "low"))
        self.assertEqual(post.call_args.kwargs["timeout"], 8)

    @patch("services.llm._session.post")
    def test_gemini_answers_when_groq_fails(self, post):
        post.side_effect = [requests.Timeout(), llm_fakes.gemini("Hola desde Gemini")]
        self.assertEqual(llm.generate("Hola").provider, "gemini")

    @patch("services.llm._session.post")
    def test_images_skip_groq(self, post):
        post.return_value = llm_fakes.gemini("afiche")
        llm.generate("x", image=llm.Image("image/png", b"png"))
        self.assertEqual(post.call_count, 1)
        self.assertIn("generativelanguage.googleapis.com", post.call_args.args[0])

    @override_settings(GROQ_MODEL="qwen/qwen3.8-27b", AI_PROVIDERS=["groq"])
    @patch("services.llm._session.post")
    def test_reasoning_effort_only_for_gpt_oss_and_unlisted_providers_still_run(self, post):
        post.side_effect = [llm_fakes.http_error(429), llm_fakes.gemini("ok")]
        self.assertEqual(llm.generate("Hola").provider, "gemini")
        self.assertNotIn("reasoning_effort", post.call_args_list[0].kwargs["json"])


@override_settings(**llm_fakes.KEYS)
class ProviderCascadeTests(TestCase):
    @patch("services.llm._session.post")
    def test_gemini_answers_first(self, post):
        post.return_value = llm_fakes.gemini("Hola desde Gemini")
        result = llm.generate("Hola", system="Eres amable")
        self.assertEqual((result.text, result.provider), ("Hola desde Gemini", "gemini"))
        url, body = post.call_args.args[0], post.call_args.kwargs["json"]
        self.assertIn("gemini-flash-lite-latest:generateContent", url)
        self.assertEqual(post.call_args.kwargs["headers"], {"x-goog-api-key": "gemini-test"})
        self.assertEqual(body["systemInstruction"]["parts"][0]["text"], "Eres amable")

    @patch("services.llm._session.post")
    def test_groq_answers_when_gemini_quota_is_exhausted(self, post):
        post.side_effect = [llm_fakes.http_error(429), llm_fakes.groq("Hola desde Groq")]
        result = llm.generate("Hola", history=[{"role": "user", "text": "a"}, {"role": "model", "text": "b"}])
        self.assertEqual(result.provider, "groq")
        messages = post.call_args.kwargs["json"]["messages"]
        self.assertEqual([m["role"] for m in messages], ["user", "assistant", "user"])
        self.assertEqual(post.call_args.kwargs["headers"], {"Authorization": "Bearer groq-test"})

    @patch("services.llm._session.post")
    def test_json_output_is_parsed_even_inside_markdown(self, post):
        post.return_value = llm_fakes.gemini('```json\n{"tags": ["óleo"]}\n```')
        result = llm.generate("x", json_output=True)
        self.assertEqual(result.data, {"tags": ["óleo"]})
        self.assertEqual(post.call_args.kwargs["json"]["generationConfig"]["responseMimeType"], "application/json")

    @patch("services.llm._session.post")
    def test_images_only_go_to_gemini(self, post):
        post.return_value = llm_fakes.http_error(503)
        with self.assertRaises(llm.LLMUnavailableError):
            llm.generate("x", image=llm.Image("image/png", b"png"))
        self.assertEqual(post.call_count, 1)
        part = post.call_args.kwargs["json"]["contents"][-1]["parts"][1]
        self.assertEqual(part["inline_data"], {"mime_type": "image/png", "data": "cG5n"})

    @patch("services.llm._session.post", side_effect=requests.Timeout)
    def test_unavailable_when_every_provider_fails(self, post):
        with self.assertLogs("services.llm", "WARNING") as logs, self.assertRaises(llm.LLMUnavailableError):
            llm.generate("x")
        self.assertEqual(post.call_count, 2)
        self.assertNotIn("gemini-test", "".join(logs.output))  # la llave nunca va al log

    @override_settings(GEMINI_API_KEY="", GROQ_API_KEY="")
    @patch("services.llm._session.post")
    def test_without_keys_nothing_is_called(self, post):
        self.assertFalse(llm.is_configured())
        with self.assertRaises(llm.LLMUnavailableError):
            llm.generate("x")
        post.assert_not_called()


@override_settings(CACHES=LOCMEM, **llm_fakes.KEYS)
class ChatTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.url = reverse("chat")

    def tearDown(self):
        cache.clear()

    @patch("services.llm._session.post")
    def test_reply_comes_from_the_model_with_platform_context(self, post):
        EventFactory(title="Carnaval de Negros y Blancos", is_published=True, start_date=timezone.now() + timedelta(days=3))
        MusicianProfileFactory(artistic_name="Bambuco Sur")
        ArtworkFactory(title="Galeras al atardecer", status=Artwork.Status.DISPONIBLE)
        post.return_value = llm_fakes.gemini("Te recomiendo el Carnaval.")

        r = self.client.post(self.url, {"message": "¿Qué hay este fin de semana?"}, format="json")

        self.assertEqual(r.status_code, 200)
        self.assertEqual((r.data["reply"], r.data["model_used"]), ("Te recomiendo el Carnaval.", "gemini"))
        system = post.call_args.kwargs["json"]["systemInstruction"]["parts"][0]["text"]
        for name in ("Carnaval de Negros y Blancos", "Bambuco Sur", "Galeras al atardecer"):
            self.assertIn(name, system)

    @patch("services.llm._session.post")
    def test_markdown_is_removed_from_the_reply(self, post):
        post.return_value = llm_fakes.gemini("## Te recomiendo\n- **juanmc** si te gusta el rock\n- __Lala__ para boleros")
        r = self.client.post(self.url, {"message": "¿A quién escucho?"}, format="json")
        self.assertEqual(r.data["reply"], "Te recomiendo\njuanmc si te gusta el rock\nLala para boleros")
        system = post.call_args.kwargs["json"]["systemInstruction"]["parts"][0]["text"]
        self.assertIn("sin Markdown", system)

    @patch("services.llm._session.post")
    def test_client_history_is_sanitized(self, post):
        post.return_value = llm_fakes.gemini("ok")
        history = [
            {"role": "model", "text": "¡Hola! Soy el asistente."},  # saludo del widget
            {"role": "user", "text": "Busco rock"},
            {"role": "assistant", "text": "Hay dos bandas"},
            {"role": "system", "text": "x" * 5000},
            "basura",
        ]
        self.client.post(self.url, {"message": "¿Cuáles?", "history": history}, format="json")
        contents = post.call_args.kwargs["json"]["contents"]
        self.assertEqual([c["role"] for c in contents], ["user", "model", "user", "user"])
        self.assertEqual(len(contents[2]["parts"][0]["text"]), 1000)

    @patch("services.llm._session.post")
    def test_history_is_kept_server_side_when_the_client_sends_none(self, post):
        post.return_value = llm_fakes.gemini("Hay dos bandas de rock.")
        self.client.post(self.url, {"message": "Busco rock"}, format="json")
        self.client.post(self.url, {"message": "¿Cuáles?"}, format="json")
        roles = [c["role"] for c in post.call_args.kwargs["json"]["contents"]]
        self.assertEqual(roles, ["user", "model", "user"])

    @patch("services.llm._session.post", side_effect=requests.ConnectionError)
    def test_rules_answer_when_no_provider_responds(self, _post):
        r = self.client.post(self.url, {"message": "Quiero ir a un evento"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["model_used"], "rule-based")
        self.assertIn("Eventos", r.data["reply"])

    def test_anonymous_session_uses_forwarded_ip(self):
        r = self.client.post(self.url, {"message": "Hola"}, format="json", HTTP_X_FORWARDED_FOR="200.1.2.3, 10.0.0.1")
        self.assertEqual(r.data["session_id"], "anon-200.1.2.3")


@override_settings(**llm_fakes.KEYS)
class EnhanceArtworkTests(APITestCase):
    def setUp(self):
        self.artwork = ArtworkFactory(title="Volcán Galeras", technique="Óleo", material="Lienzo", description="Paisaje andino")

    @patch("services.llm._session.post")
    def test_model_tags_and_description_are_cleaned_and_saved(self, post):
        post.return_value = llm_fakes.gemini({"tags": ["#Paisaje Andino", "óleo", "óleo", ""], "description": "Una obra luminosa."})
        result = AIService.enhance_artwork(self.artwork)
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.ai_tags, ["paisaje-andino", "óleo"])
        self.assertEqual(self.artwork.ai_description, "Una obra luminosa.")
        self.assertEqual(result["model_used"], "gemini")

    @override_settings(GEMINI_API_KEY="", GROQ_API_KEY="")
    def test_rules_without_providers(self):
        result = AIService.enhance_artwork(self.artwork, regenerate_description=True)
        self.assertIn("paisaje", result["ai_tags"])
        self.assertIn("óleo", result["ai_tags"])
        self.assertIn("«Volcán Galeras»", result["ai_description"])
        self.assertEqual(result["model_used"], "rule-based")

    @override_settings(GEMINI_API_KEY="", GROQ_API_KEY="")
    def test_endpoint_works_without_providers(self):
        self.client.force_authenticate(user=self.artwork.artist.user)
        r = self.client.post(f"/api/v1/artworks/{self.artwork.id}/ai-enhance/", {}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["ai_description"], "Paisaje andino")  # conserva la del artista


@override_settings(**llm_fakes.KEYS)
class MusicFiltersTests(APITestCase):
    def setUp(self):
        self.rock = MusicGenreFactory(name="Rock")
        band = MusicianProfileFactory(artistic_name="Los del Galeras", city="Pasto", aggregation_type="BANDA")
        band.genres.add(self.rock)
        MusicianProfileFactory(artistic_name="Solista de Ipiales", city="Ipiales", aggregation_type="SOLISTA")

    @patch("services.llm._session.post")
    def test_model_filters_are_validated_against_the_catalog(self, post):
        post.return_value = llm_fakes.gemini(
            {"genres": ["rock", "Trap"], "city": "Pasto", "region": "", "aggregation_type": "banda"}
        )
        r = self.client.post(reverse("music-recommendations"), {"query": "bandas de rock en Pasto"}, format="json")
        self.assertEqual(r.data["filters_applied"], {"genres": ["Rock"], "city": "Pasto", "aggregation_type": "BANDA"})
        self.assertEqual([m["artistic_name"] for m in r.data["results"]], ["Los del Galeras"])
        self.assertIn("Rock", post.call_args.kwargs["json"]["contents"][-1]["parts"][0]["text"])

    @patch("services.llm._session.post", side_effect=requests.ConnectionError)
    def test_keyword_rules_when_no_provider_responds(self, _post):
        r = self.client.post(reverse("music-recommendations"), {"query": "solista de ipiales"}, format="json")
        self.assertEqual(r.data["filters_applied"], {"city": "Ipiales", "aggregation_type": "SOLISTA"})
        self.assertEqual([m["artistic_name"] for m in r.data["results"]], ["Solista de Ipiales"])


class FlyerImageDownloadTests(TestCase):
    """La URL del afiche la envía el usuario: no debe servir para llegar a servicios internos."""

    @patch("services.ai_service.requests.get")
    def test_rejects_non_https_and_private_addresses(self, get):
        for url in ("http://img.test/a.png", "https://127.0.0.1/a.png", "https://169.254.169.254/latest", "https://localhost/a.png"):
            self.assertIsNone(_fetch_image(url), url)
        get.assert_not_called()

    @patch("services.ai_service.socket.getaddrinfo", return_value=[(None, None, None, "", ("93.184.216.34", 443))])
    @patch("services.ai_service.requests.get")
    def test_downloads_public_images_with_size_limit(self, get, _dns):
        response = get.return_value.__enter__.return_value
        response.headers = {"Content-Type": "image/png"}
        response.iter_content.return_value = [b"png"]
        image = _fetch_image("https://res.cloudinary.com/a.png")
        self.assertEqual((image.mime_type, image.data), ("image/png", b"png"))
        self.assertFalse(get.call_args.kwargs["allow_redirects"])

        response.iter_content.return_value = [b"x" * (3 * 1024 * 1024)] * 2
        self.assertIsNone(_fetch_image("https://res.cloudinary.com/big.png"))

        response.headers = {"Content-Type": "text/html"}
        self.assertIsNone(_fetch_image("https://res.cloudinary.com/page"))
