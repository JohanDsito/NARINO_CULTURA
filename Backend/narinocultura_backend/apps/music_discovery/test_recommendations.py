"""Búsqueda de músicos en lenguaje natural: filtros con IA, respaldo local y búsqueda libre."""
from unittest.mock import MagicMock, patch

import httpx
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from tests.factories import MusicGenreFactory, MusicianProfileFactory

AI_URL = "http://ai.test"


def ai_client_returning(status_code=200, payload=None, error=None):
    """Simula httpx.Client como gestor de contexto con la respuesta (o el error) indicado."""
    client_cls = MagicMock()
    post = client_cls.return_value.__enter__.return_value.post
    if error is not None:
        post.side_effect = error
    else:
        post.return_value.status_code = status_code
        post.return_value.json.return_value = payload or {}
    return client_cls


class LocalRecommendationTests(APITestCase):
    """Sin AI_SERVICE_URL la consulta se interpreta con palabras clave."""

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
        from apps.music_discovery.views import MusicRecommendationView

        filters = MusicRecommendationView()._parse_locally("dúo de chirimia en túquerres")
        self.assertEqual(filters, {"genres": ["Chirimía"], "city": "Túquerres", "aggregation_type": "DUO"})


@override_settings(AI_SERVICE_URL=AI_URL)
class AIRecommendationTests(APITestCase):
    """Con AI_SERVICE_URL se delega el análisis al microservicio y, si falla, se usa el local."""

    def setUp(self):
        self.url = reverse("music-recommendations")
        jazz = MusicGenreFactory(name="Jazz", slug="jazz")
        self.jazz_trio = MusicianProfileFactory(artistic_name="Trío Galeras", aggregation_type="TRIO", city="Pasto")
        self.jazz_trio.genres.add(jazz)
        rock = MusicGenreFactory(name="Rock", slug="rock")
        self.rocker = MusicianProfileFactory(artistic_name="Rockero", city="Ipiales")
        self.rocker.genres.add(rock)

    def test_uses_filters_returned_by_ai(self):
        ai_filters = {"genres": ["Jazz"], "city": "Pasto", "aggregation_type": "TRIO"}
        client_cls = ai_client_returning(payload=ai_filters)
        with patch("apps.music_discovery.views.httpx.Client", client_cls):
            response = self.client.post(self.url, {"query": "algo suave para la noche"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["filters_applied"], ai_filters)
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Trío Galeras"])
        client_cls.return_value.__enter__.return_value.post.assert_called_once_with(
            f"{AI_URL}/music/recommendations", json={"query": "algo suave para la noche"}
        )

    def test_ai_region_filter_is_applied(self):
        self.rocker.region = "Putumayo"
        self.rocker.save()
        with patch("apps.music_discovery.views.httpx.Client", ai_client_returning(payload={"region": "Putumayo"})):
            response = self.client.post(self.url, {"query": "del sur"}, format="json")
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Rockero"])

    def test_falls_back_to_keywords_when_ai_answers_with_error_status(self):
        with patch("apps.music_discovery.views.httpx.Client", ai_client_returning(status_code=500)):
            response = self.client.post(self.url, {"query": "rock"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"genres": ["Rock"]})
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Rockero"])

    def test_falls_back_to_keywords_when_ai_is_unreachable(self):
        error = httpx.ConnectError("sin conexión")
        with patch("apps.music_discovery.views.httpx.Client", ai_client_returning(error=error)):
            response = self.client.post(self.url, {"query": "jazz en pasto"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["filters_applied"], {"genres": ["Jazz"], "city": "Pasto"})

    def test_falls_back_when_ai_returns_invalid_json(self):
        client_cls = ai_client_returning()
        client_cls.return_value.__enter__.return_value.post.return_value.json.side_effect = ValueError("no JSON")
        with patch("apps.music_discovery.views.httpx.Client", client_cls):
            response = self.client.post(self.url, {"query": "rock"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"genres": ["Rock"]})

    def test_falls_back_when_ai_returns_no_filters(self):
        with patch("apps.music_discovery.views.httpx.Client", ai_client_returning(payload={})):
            response = self.client.post(self.url, {"query": "trio"}, format="json")
        self.assertEqual(response.data["filters_applied"], {"aggregation_type": "TRIO"})
        self.assertEqual([r["artistic_name"] for r in response.data["results"]], ["Trío Galeras"])
