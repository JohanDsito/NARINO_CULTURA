"""Límites por minuto de los endpoints que consumen la cuota de la IA."""
from django.core.cache import cache
from django.test import override_settings
from django.urls import reverse
from rest_framework.test import APITestCase

from tests.factories import ArtworkFactory

LOCMEM = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache", "LOCATION": "ai-throttle"}}


@override_settings(CACHES=LOCMEM)
class AIThrottleTests(APITestCase):
    def setUp(self):
        cache.clear()

    def tearDown(self):
        cache.clear()

    def test_music_search_allows_20_requests_per_minute(self):
        url = reverse("music-recommendations")
        codes = [self.client.post(url, {"query": "rock"}, format="json").status_code for _ in range(21)]
        self.assertEqual(codes[:20], [200] * 20)
        self.assertEqual(codes[20], 429)

    def test_chat_keeps_the_global_hourly_limit_besides_its_own(self):
        from apps.music_discovery.views import ChatAPIView

        names = {cls.__name__ for cls in ChatAPIView.throttle_classes}
        self.assertEqual(names, {"ScopedRateThrottle", "AnonRateThrottle", "UserRateThrottle"})

    def test_ai_enhance_is_limited_per_user(self):
        artwork = ArtworkFactory()
        self.client.force_authenticate(user=artwork.artist.user)
        url = f"/api/v1/artworks/{artwork.id}/ai-enhance/"
        codes = [self.client.post(url, {}, format="json").status_code for _ in range(21)]
        self.assertEqual(codes[:20], [200] * 20)
        self.assertEqual(codes[20], 429)
