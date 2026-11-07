from django.db import connection
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APITestCase

from apps.artists.models import Follow
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory

URL = "/api/v1/artists/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class ArtistProfileStatsTests(APITestCase):
    """is_following, artworks_count y /artists/me/ (pedido de la app móvil)."""

    def setUp(self):
        self.fan = UserFactory()
        self.artist = ArtistProfileFactory()
        ArtworkFactory(artist=self.artist, status="DISPONIBLE")
        ArtworkFactory(artist=self.artist, status="VENDIDA")
        ArtworkFactory(artist=self.artist, status="INACTIVA")  # pendiente de moderación: no cuenta
        self.client.force_authenticate(user=self.fan)
        self.client.post(f"{URL}{self.artist.slug}/follow/")

    def item(self, response, profile):
        return next(a for a in results(response) if a["slug"] == profile.slug)

    def test_list_and_detail_include_stats(self):
        for data in (self.item(self.client.get(URL), self.artist), self.client.get(f"{URL}{self.artist.slug}/").data):
            self.assertTrue(data["is_following"])
            self.assertEqual(data["artworks_count"], 2)
            self.assertEqual(data["followers_count"], 1)

    def test_anonymous_is_never_following(self):
        self.client.force_authenticate(user=None)
        self.assertFalse(self.client.get(f"{URL}{self.artist.slug}/").data["is_following"])

    def test_following_count_counts_artists_the_profile_owner_follows(self):
        Follow.objects.create(follower=self.artist.user, artist=ArtistProfileFactory())
        self.assertEqual(self.client.get(f"{URL}{self.artist.slug}/").data["following_count"], 1)

    def test_list_query_count_does_not_grow_with_artists(self):
        with CaptureQueriesContext(connection) as few:
            self.client.get(URL)
        for _ in range(4):
            ArtworkFactory(artist=ArtistProfileFactory(), status="DISPONIBLE")
        with CaptureQueriesContext(connection) as many:
            r = self.client.get(URL)
        self.assertEqual(len(results(r)), 5)
        self.assertEqual(len(many), len(few))


class ArtistMeTests(APITestCase):
    def test_returns_own_profile(self):
        artist = ArtistProfileFactory(artistic_name="Ana Pintora")
        self.client.force_authenticate(user=artist.user)
        r = self.client.get(f"{URL}me/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["slug"], artist.slug)
        self.assertEqual(r.data["artistic_name"], "Ana Pintora")

    def test_includes_private_profile_of_the_owner(self):
        artist = ArtistProfileFactory(is_public=False)
        self.client.force_authenticate(user=artist.user)
        self.assertEqual(self.client.get(f"{URL}me/").data["slug"], artist.slug)

    def test_user_without_profile_gets_404(self):
        self.client.force_authenticate(user=UserFactory())
        r = self.client.get(f"{URL}me/")
        self.assertEqual(r.status_code, 404)
        self.assertIn("perfil de artista", r.data["detail"])

    def test_anonymous_gets_401(self):
        self.assertEqual(self.client.get(f"{URL}me/").status_code, 401)
