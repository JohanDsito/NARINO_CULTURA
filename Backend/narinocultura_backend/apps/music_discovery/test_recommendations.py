"""Búsqueda de músicos en lenguaje natural: filtros con IA, respaldo local y búsqueda libre."""
from unittest.mock import patch

import requests
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from services import ai_rules
from tests import llm_fakes
from tests.factories import MusicGenreFactory, MusicianProfileFactory

LLM_POST = "services.llm.requests.post"


class LocalRecommendationTests(APITestCase):
    """Sin llaves de IA la consulta se interpreta con palabras clave."""

    def setUp(self):
        self.url = reverse("music-recommendations")
        self.rock = MusicGenreFactory(name="Rock", slug="rock")
        self.salsa = MusicGenreFactory(name="Salsa", slug="salsa")
        self.rock_band = MusicianProfileFactory(
            artistic_name="Los Volcanes", aggregation_type="BANDA", city="Pasto", popularity_score=5
        )
        self.rock_band.genres.add(self.rock)
        self.rock_solo = MusicianProfileFactory(
            artistic_name="Solo Rock", aggregation_type="SOLISTA", city="Ipiales", popularity_score=9
        )
        self.rock_solo.genres.add(self.rock)
        self.salsa_band = MusicianProfileFactory(
            artistic_name="Sabor Andino", aggregation_type="BANDA", city="Pasto", region="Nariño",
            bio="Salsa brava del sur",
        )
        self.salsa_band.genres.add(self.salsa)

    def names(self, response):
        return [item["artistic_name"] for item in response.data["results"]]

    def test_combines_genre_city_and_type_keywords(self):
        """'banda de rock en pasto' aplica género, ciudad y tipo de agrupación."""
        response = self.client.post(self.url, {"query": "Banda de ROCK en Pasto"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            response.data["filters_applied"],
            {"genres": ["Rock"], "city": "Pasto", "aggregation_type": "BANDA"},
        )
        self.assertEqual(self.names(response), ["Los Volcanes"])
        self.assertEqual(response.data["count"], 1)

    def test_genre_results_are_sorted_by_popularity(self):
        response = self.client.post(self.url, {"query": "rock"}, format="json")
        self.assertEqual(self.names(response), ["Solo Rock", "Los Volcanes"])

    def test_narino_is_used_as_region_filter(self):
        """'Nariño' no es una ciudad: se filtra por región."""
        response = self.client.post(self.url, {"query": "músicos de nariño"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"region": "Nariño"})
        self.assertEqual(self.names(response), ["Sabor Andino"])

    def test_inactive_profiles_are_excluded(self):
        self.rock_solo.is_active = False
        self.rock_solo.save()
        response = self.client.post(self.url, {"query": "rock"}, format="json")
        self.assertEqual(self.names(response), ["Los Volcanes"])

    def test_without_keywords_searches_name_and_bio(self):
        """Sin palabras clave se busca el texto en el nombre artístico o la biografía."""
        by_name = self.client.post(self.url, {"query": "Volcanes"}, format="json")
        self.assertEqual(by_name.data["filters_applied"], {})
        self.assertEqual(self.names(by_name), ["Los Volcanes"])

        by_bio = self.client.post(self.url, {"query": "brava"}, format="json")
        self.assertEqual(self.names(by_bio), ["Sabor Andino"])

    def test_query_is_trimmed(self):
        response = self.client.post(self.url, {"query": "   "}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        response = self.client.post(self.url, {"query": "  salsa  "}, format="json")
        self.assertEqual(response.data["query"], "salsa")
        self.assertEqual(self.names(response), ["Sabor Andino"])

    def test_parse_locally_maps_accents_and_variants(self):
        filters = ai_rules.music_filters("dúo de chirimia en túquerres")
        self.assertEqual(filters, {"genres": ["Chirimía"], "city": "Túquerres", "aggregation_type": "DUO"})


@override_settings(**llm_fakes.KEYS)
class AIRecommendationTests(APITestCase):
    """Con IA configurada la consulta la interpreta el modelo y, si falla, se usan las reglas."""

    def setUp(self):
        self.url = reverse("music-recommendations")
        jazz = MusicGenreFactory(name="Jazz", slug="jazz")
        self.jazz_trio = MusicianProfileFactory(artistic_name="Trío Galeras", aggregation_type="TRIO", city="Pasto")
        self.jazz_trio.genres.add(jazz)
        rock = MusicGenreFactory(name="Rock", slug="rock")
        self.rocker = MusicianProfileFactory(artistic_name="Rockero", city="Ipiales")
        self.rocker.genres.add(rock)

    @patch(LLM_POST)
    def test_uses_filters_returned_by_ai(self, post):
        ai_filters = {"genres": ["Jazz"], "city": "Pasto", "aggregation_type": "TRIO"}
        post.return_value = llm_fakes.gemini(ai_filters)
        response = self.client.post(self.url, {"query": "algo suave para la noche"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["filters_applied"], ai_filters)
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Trío Galeras"])
        prompt = post.call_args.kwargs["json"]["contents"][-1]["parts"][0]["text"]
        self.assertIn("algo suave para la noche", prompt)

    @patch(LLM_POST)
    def test_ai_region_filter_is_applied(self, post):
        self.rocker.region = "Putumayo"
        self.rocker.save()
        post.return_value = llm_fakes.gemini({"region": "Putumayo"})
        response = self.client.post(self.url, {"query": "del sur"}, format="json")
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Rockero"])

    @patch(LLM_POST)
    def test_genres_outside_the_catalog_are_discarded(self, post):
        post.return_value = llm_fakes.gemini({"genres": ["Trap", "rock"], "aggregation_type": "ORQUESTA"})
        response = self.client.post(self.url, {"query": "algo urbano"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"genres": ["Rock"]})

    @patch(LLM_POST)
    def test_falls_back_to_keywords_when_ai_answers_with_error_status(self, post):
        post.return_value = llm_fakes.http_error(500)
        response = self.client.post(self.url, {"query": "rock"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"genres": ["Rock"]})
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Rockero"])

    @patch(LLM_POST, side_effect=requests.ConnectionError("sin conexión"))
    def test_falls_back_to_keywords_when_ai_is_unreachable(self, _post):
        response = self.client.post(self.url, {"query": "jazz en pasto"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["filters_applied"], {"genres": ["Jazz"], "city": "Pasto"})

    @patch(LLM_POST)
    def test_falls_back_when_ai_returns_invalid_json(self, post):
        post.return_value = llm_fakes.gemini("no es JSON")
        response = self.client.post(self.url, {"query": "rock"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"genres": ["Rock"]})

    @patch(LLM_POST)
    def test_falls_back_when_ai_returns_no_filters(self, post):
        post.return_value = llm_fakes.gemini({})
        response = self.client.post(self.url, {"query": "trio"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"aggregation_type": "TRIO"})
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Trío Galeras"])
