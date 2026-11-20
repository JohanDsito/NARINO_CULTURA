"""Acciones del artista sobre sus obras: catálogo propio, borrado por admin y mejora con IA."""
from decimal import Decimal
from unittest.mock import MagicMock, patch

import requests
from django.test import override_settings
from rest_framework.test import APITestCase

from apps.artworks.models import Artwork
from apps.marketplace.models import Order, OrderItem
from tests.factories import AdminUserFactory, ArtistProfileFactory, ArtworkFactory, UserFactory

URL = "/api/v1/artworks/"


def ids(response):
    return {item["id"] for item in response.data["results"]}


class ArtistCatalogTests(APITestCase):
    """?artist=<slug> y ?mine=true: el dueño ve sus obras inactivas, el resto solo las públicas."""

    def setUp(self):
        self.profile = ArtistProfileFactory()
        self.public = ArtworkFactory(artist=self.profile, status=Artwork.Status.DISPONIBLE)
        self.hidden = ArtworkFactory(artist=self.profile, status=Artwork.Status.INACTIVA)
        self.foreign = ArtworkFactory(status=Artwork.Status.DISPONIBLE)

    def test_owner_sees_all_own_artworks_by_slug(self):
        self.client.force_authenticate(user=self.profile.user)
        r = self.client.get(f"{URL}?artist={self.profile.slug}")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(ids(r), {str(self.public.id), str(self.hidden.id)})

    def test_visitor_only_sees_public_artworks_of_artist(self):
        self.client.force_authenticate(user=UserFactory())
        r = self.client.get(f"{URL}?artist={self.profile.slug}")
        self.assertEqual(ids(r), {str(self.public.id)})

    def test_anonymous_only_sees_public_artworks_of_artist(self):
        r = self.client.get(f"{URL}?artist={self.profile.slug}")
        self.assertEqual(ids(r), {str(self.public.id)})

    def test_mine_returns_only_own_artworks_including_inactive(self):
        self.client.force_authenticate(user=self.profile.user)
        r = self.client.get(f"{URL}?mine=true")
        self.assertEqual(ids(r), {str(self.public.id), str(self.hidden.id)})

    def test_mine_without_artist_profile_is_empty(self):
        self.client.force_authenticate(user=UserFactory())
        r = self.client.get(f"{URL}?mine=true")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["results"], [])

    def test_mine_is_ignored_for_anonymous(self):
        r = self.client.get(f"{URL}?mine=true")
        self.assertEqual(ids(r), {str(self.public.id), str(self.foreign.id)})

    def test_inactive_artwork_detail_is_hidden_from_public(self):
        r = self.client.get(f"{URL}{self.hidden.id}/")
        self.assertEqual(r.status_code, 404)

    def test_user_without_artist_profile_cannot_create(self):
        self.client.force_authenticate(user=UserFactory())
        r = self.client.post(URL, {"title": "Sin perfil", "price": "1000"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["detail"], "Perfil de artista no encontrado.")

    def test_created_artwork_belongs_to_artist_and_starts_inactive(self):
        self.client.force_authenticate(user=self.profile.user)
        r = self.client.post(URL, {"title": "Nueva", "price": "5000", "status": "DISPONIBLE"}, format="json")
        self.assertEqual(r.status_code, 201)
        artwork = Artwork.objects.get(id=r.data["id"])
        self.assertEqual(artwork.artist, self.profile)
        # status es de solo lectura: toda obra nueva pasa por moderación
        self.assertEqual(artwork.status, Artwork.Status.INACTIVA)

    def test_owner_can_delete_own_artwork(self):
        self.client.force_authenticate(user=self.profile.user)
        r = self.client.delete(f"{URL}{self.public.id}/")
        self.assertEqual(r.status_code, 204)
        self.assertFalse(Artwork.objects.filter(id=self.public.id).exists())

    def test_other_user_cannot_delete_artwork(self):
        self.client.force_authenticate(user=UserFactory())
        r = self.client.delete(f"{URL}{self.public.id}/")
        self.assertEqual(r.status_code, 403)
        self.assertTrue(Artwork.objects.filter(id=self.public.id).exists())


class AdminDeleteArtworkTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory()
        self.artwork = ArtworkFactory()

    def _delete(self, artwork_id):
        return self.client.delete(f"{URL}{artwork_id}/delete/")

    def test_admin_deletes_artwork(self):
        self.client.force_authenticate(user=self.admin)
        r = self._delete(self.artwork.id)
        self.assertEqual(r.status_code, 204)
        self.assertFalse(Artwork.objects.filter(id=self.artwork.id).exists())

    def test_admin_can_delete_inactive_artwork(self):
        hidden = ArtworkFactory(status=Artwork.Status.INACTIVA)
        self.client.force_authenticate(user=self.admin)
        self.assertEqual(self._delete(hidden.id).status_code, 204)

    def test_unknown_artwork_returns_404(self):
        self.client.force_authenticate(user=self.admin)
        r = self._delete("00000000-0000-0000-0000-000000000000")
        self.assertEqual(r.status_code, 404)
        self.assertEqual(r.data["detail"], "Obra no encontrada.")

    def test_artwork_with_orders_returns_409_and_is_kept(self):
        order = Order.objects.create(buyer=UserFactory(), total_amount=Decimal("150000.00"))
        OrderItem.objects.create(order=order, artwork=self.artwork, price=Decimal("150000.00"))
        self.client.force_authenticate(user=self.admin)
        r = self._delete(self.artwork.id)
        self.assertEqual(r.status_code, 409)
        self.assertIn("INACTIVA", r.data["detail"])
        self.assertTrue(Artwork.objects.filter(id=self.artwork.id).exists())

    def test_owner_without_admin_role_gets_403(self):
        self.client.force_authenticate(user=self.artwork.artist.user)
        self.assertEqual(self._delete(self.artwork.id).status_code, 403)
        self.assertTrue(Artwork.objects.filter(id=self.artwork.id).exists())

    def test_anonymous_gets_401(self):
        self.assertEqual(self._delete(self.artwork.id).status_code, 401)


class ArtworkAIEnhanceTests(APITestCase):
    def setUp(self):
        self.artwork = ArtworkFactory(title="Volcán Galeras", technique="Óleo")
        self.owner = self.artwork.artist.user
        self.url = f"{URL}{self.artwork.id}/ai-enhance/"

    @patch("apps.artworks.views.AIService.enhance_artwork")
    def test_owner_gets_enhanced_data(self, mock_enhance):
        mock_enhance.return_value = {"ai_tags": {"estilo": "paisaje"}, "ai_description": "Texto IA"}
        self.client.force_authenticate(user=self.owner)
        r = self.client.post(self.url, {"regenerate_description": True}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["ai_description"], "Texto IA")
        mock_enhance.assert_called_once_with(artwork=self.artwork, regenerate_description=True)

    @patch("apps.artworks.views.AIService.enhance_artwork")
    def test_regenerate_description_defaults_to_false(self, mock_enhance):
        mock_enhance.return_value = {"ai_tags": {}, "ai_description": ""}
        self.client.force_authenticate(user=self.owner)
        self.client.post(self.url, {}, format="json")
        self.assertFalse(mock_enhance.call_args.kwargs["regenerate_description"])

    def test_invalid_flag_returns_400(self):
        self.client.force_authenticate(user=self.owner)
        r = self.client.post(self.url, {"regenerate_description": "quizas"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("regenerate_description", r.data)

    def test_service_not_configured_returns_400(self):
        # En test AI_SERVICE_URL está vacío: el servicio real responde con un error controlado
        self.client.force_authenticate(user=self.owner)
        r = self.client.post(self.url, {}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["detail"], "Servicio de IA no configurado.")

    @override_settings(AI_SERVICE_URL="http://ia.local/")
    @patch("services.ai_service.requests.post")
    def test_microservice_response_is_saved_on_artwork(self, mock_post):
        mock_post.return_value = MagicMock(
            content=b"{}", json=lambda: {"tags": {"tema": "volcan"}, "ai_description": "Paisaje andino"}
        )
        self.client.force_authenticate(user=self.owner)
        r = self.client.post(self.url, {}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data, {"ai_tags": {"tema": "volcan"}, "ai_description": "Paisaje andino"})
        self.assertEqual(mock_post.call_args.args[0], "http://ia.local/artworks/enhance")
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.ai_description, "Paisaje andino")

    @override_settings(AI_SERVICE_URL="http://ia.local")
    @patch("services.ai_service.requests.post", side_effect=requests.ConnectionError("caído"))
    def test_microservice_down_returns_400(self, _mock_post):
        self.client.force_authenticate(user=self.owner)
        r = self.client.post(self.url, {}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["detail"], "No fue posible contactar el microservicio de IA.")

    @patch("apps.artworks.views.AIService.enhance_artwork")
    def test_non_owner_gets_403(self, mock_enhance):
        self.client.force_authenticate(user=UserFactory())
        r = self.client.post(self.url, {}, format="json")
        self.assertEqual(r.status_code, 403)
        mock_enhance.assert_not_called()

    def test_anonymous_gets_401(self):
        self.assertEqual(self.client.post(self.url, {}, format="json").status_code, 401)
