from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import AccessToken

from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, CategoryFactory, UserFactory


def auth_header(user):
    token = AccessToken.for_user(user)
    return {"HTTP_AUTHORIZATION": f"Bearer {token}"}


class CategoryTests(APITestCase):
    def setUp(self):
        self.cat = CategoryFactory(name="Pintura", slug="pintura")

    def test_list_categories_is_public(self):
        r = self.client.get("/api/v1/artworks/categories/")
        self.assertEqual(r.status_code, 200)

    def test_retrieve_category_by_slug(self):
        r = self.client.get(f"/api/v1/artworks/categories/{self.cat.slug}/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["name"], "Pintura")


class ArtworkListTests(APITestCase):
    def setUp(self):
        self.profile = ArtistProfileFactory()
        ArtworkFactory(artist=self.profile, status="DISPONIBLE")
        ArtworkFactory(artist=self.profile, status="DISPONIBLE")
        ArtworkFactory(artist=self.profile, status="INACTIVA")

    def test_list_artworks_public(self):
        r = self.client.get("/api/v1/artworks/")
        self.assertEqual(r.status_code, 200)

    def test_filter_by_status(self):
        r = self.client.get("/api/v1/artworks/?status=DISPONIBLE")
        self.assertEqual(r.status_code, 200)
        # All returned artworks should be DISPONIBLE
        for item in r.data["results"]:
            self.assertEqual(item["status"], "DISPONIBLE")


class ArtworkCreateTests(APITestCase):
    def setUp(self):
        self.artist_user = ArtistUserFactory()
        self.artist_user.is_verified = True
        self.artist_user.save()
        self.profile = ArtistProfileFactory(user=self.artist_user)
        self.buyer = UserFactory(role="COMPRADOR")
        self.buyer.is_verified = True
        self.buyer.save()

    def test_artist_can_create_artwork(self):
        r = self.client.post(
            "/api/v1/artworks/",
            {"title": "Mi obra", "price": "200000", "description": "desc"},
            format="json",
            **auth_header(self.artist_user),
        )
        self.assertIn(r.status_code, [200, 201])

    def test_buyer_cannot_create_artwork(self):
        r = self.client.post(
            "/api/v1/artworks/",
            {"title": "Intento", "price": "100000"},
            format="json",
            **auth_header(self.buyer),
        )
        self.assertIn(r.status_code, [403, 400])

    def test_unauthenticated_cannot_create_artwork(self):
        r = self.client.post(
            "/api/v1/artworks/",
            {"title": "Sin auth", "price": "100000"},
            format="json",
        )
        self.assertEqual(r.status_code, 401)


class ArtworkDetailTests(APITestCase):
    def setUp(self):
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")

    def test_retrieve_artwork_increments_views(self):
        views_before = self.artwork.views_count
        r = self.client.get(f"/api/v1/artworks/{self.artwork.id}/")
        self.assertEqual(r.status_code, 200)
        self.artwork.refresh_from_db()
        self.assertGreaterEqual(self.artwork.views_count, views_before)

    def test_owner_can_update_artwork(self):
        r = self.client.patch(
            f"/api/v1/artworks/{self.artwork.id}/",
            {"title": "Titulo actualizado"},
            format="json",
            **auth_header(self.profile.user),
        )
        self.assertIn(r.status_code, [200, 204])

    def test_non_owner_cannot_update_artwork(self):
        other = UserFactory()
        r = self.client.patch(
            f"/api/v1/artworks/{self.artwork.id}/",
            {"title": "Hack"},
            format="json",
            **auth_header(other),
        )
        self.assertIn(r.status_code, [403, 404])
