from django.core.cache import cache
from django.test import override_settings
from rest_framework.test import APITestCase

from apps.artworks.models import Artwork
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory

URL = "/api/v1/artworks/"
LOCMEM = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache", "LOCATION": "views-test"}}


def titles(response):
    data = response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data
    return {a["title"] for a in data}


class CatalogFilterTests(APITestCase):
    """Filtros del catálogo en el servidor: technique, price_min y price_max."""

    def setUp(self):
        artist = ArtistProfileFactory()
        ArtworkFactory(artist=artist, title="Acrílico barato", technique="Acrilico sobre lienzo", price="50000.00")
        ArtworkFactory(artist=artist, title="Acrílico caro", technique="acrilico", price="900000.00")
        ArtworkFactory(artist=artist, title="Acuarela", technique="Acuarela", price="120000.00")
        ArtworkFactory(artist=artist, title="Oculta", technique="Acrilico", price="60000.00", status="INACTIVA")

    def test_technique_is_case_insensitive_partial_match(self):
        # En PostgreSQL también ignora mayúsculas con tildes ("ÓLEO" = "óleo"); SQLite solo en ASCII
        self.assertEqual(titles(self.client.get(URL, {"technique": "ACRIL"})), {"Acrílico barato", "Acrílico caro"})

    def test_price_range(self):
        r = self.client.get(URL, {"price_min": "100000", "price_max": "500000"})
        self.assertEqual(titles(r), {"Acuarela"})

    def test_filters_combine(self):
        r = self.client.get(URL, {"technique": "acrilico", "price_max": "100000"})
        self.assertEqual(titles(r), {"Acrílico barato"})

    def test_filters_never_show_hidden_artworks(self):
        self.assertNotIn("Oculta", titles(self.client.get(URL, {"technique": "acrilico"})))

    def test_invalid_price_is_rejected(self):
        self.assertEqual(self.client.get(URL, {"price_min": "abc"}).status_code, 400)


@override_settings(CACHES=LOCMEM, ARTWORK_VIEW_WINDOW_SECONDS=3600)
class UniqueViewsTests(APITestCase):
    """Recargar el detalle de una obra no infla views_count."""

    def setUp(self):
        cache.clear()
        self.artwork = ArtworkFactory(artist=ArtistProfileFactory())
        self.url = f"{URL}{self.artwork.id}/"

    def views(self):
        return Artwork.objects.get(id=self.artwork.id).views_count

    def test_reloading_counts_once_per_user(self):
        self.client.force_authenticate(user=UserFactory())
        first = self.client.get(self.url).data["views_count"]
        self.client.get(self.url)
        self.client.get(self.url)
        self.assertEqual(first, 1)
        self.assertEqual(self.views(), 1)

    def test_different_users_count_separately(self):
        for _ in range(3):
            self.client.force_authenticate(user=UserFactory())
            self.client.get(self.url)
        self.assertEqual(self.views(), 3)

    def test_anonymous_visitors_are_counted_by_ip(self):
        self.client.get(self.url, REMOTE_ADDR="10.0.0.1")
        self.client.get(self.url, REMOTE_ADDR="10.0.0.1")
        self.client.get(self.url, HTTP_X_FORWARDED_FOR="200.1.1.1, 10.0.0.9")
        self.assertEqual(self.views(), 2)

    @override_settings(ARTWORK_VIEW_WINDOW_SECONDS=0)
    def test_window_of_zero_counts_every_view(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        self.client.get(self.url)
        cache.clear()
        self.client.get(self.url)
        self.assertEqual(self.views(), 2)
