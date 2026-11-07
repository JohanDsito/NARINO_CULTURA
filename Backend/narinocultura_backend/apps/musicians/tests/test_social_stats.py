from django.db import connection
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APITestCase

from apps.musicians.models import MusicianFollower, MusicianReview
from tests.factories import MusicianProfileFactory, UserFactory

URL = "/api/v1/musicians/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class MusicianSocialStatsTests(APITestCase):
    """is_following, average_rating y reviews_count para la app móvil (aporte de Valery Rosero)."""

    def setUp(self):
        self.fan = UserFactory()
        self.musician = MusicianProfileFactory()
        self.other = MusicianProfileFactory()
        MusicianFollower.objects.create(user=self.fan, musician=self.musician)
        for rating in (5, 4, 4):
            MusicianReview.objects.create(musician=self.musician, reviewer=UserFactory(), rating=rating)

    def item(self, response, profile):
        return next(m for m in results(response) if m["slug"] == profile.slug)

    def test_list_includes_social_stats(self):
        self.client.force_authenticate(user=self.fan)
        r = self.client.get(URL)
        data = self.item(r, self.musician)
        self.assertTrue(data["is_following"])
        self.assertEqual(data["average_rating"], 4.3)
        self.assertEqual(data["reviews_count"], 3)
        other = self.item(r, self.other)
        self.assertFalse(other["is_following"])
        self.assertEqual(other["average_rating"], 0.0)
        self.assertEqual(other["reviews_count"], 0)

    def test_detail_includes_social_stats(self):
        self.client.force_authenticate(user=self.fan)
        data = self.client.get(f"{URL}{self.musician.slug}/").data
        self.assertTrue(data["is_following"])
        self.assertEqual(data["average_rating"], 4.3)
        self.assertEqual(data["reviews_count"], 3)

    def test_anonymous_user_is_never_following(self):
        data = self.item(self.client.get(URL), self.musician)
        self.assertFalse(data["is_following"])
        self.assertEqual(data["reviews_count"], 3)

    def test_follow_state_changes_after_toggling(self):
        self.client.force_authenticate(user=self.fan)
        self.client.post(f"{URL}{self.musician.slug}/follow/")
        self.assertFalse(self.client.get(f"{URL}{self.musician.slug}/").data["is_following"])

    def test_list_query_count_does_not_grow_with_musicians(self):
        self.client.force_authenticate(user=self.fan)
        with CaptureQueriesContext(connection) as few:
            self.client.get(URL)
        for _ in range(5):
            profile = MusicianProfileFactory()
            MusicianReview.objects.create(musician=profile, reviewer=UserFactory(), rating=3)
        with CaptureQueriesContext(connection) as many:
            r = self.client.get(URL)
        self.assertEqual(len(results(r)), 7)
        self.assertEqual(len(many), len(few))

    def test_unfollow_with_out_of_sync_counter_does_not_fail(self):
        """El seguimiento existe pero el contador está en 0: dejar de seguir no debe dar error 500."""
        self.client.force_authenticate(user=self.fan)
        r = self.client.post(f"{URL}{self.musician.slug}/follow/")
        self.assertEqual(r.status_code, 200)
        self.musician.refresh_from_db()
        self.assertEqual(self.musician.followers_count, 0)
