"""
Tests for the musicians module.
Run with: DJANGO_SETTINGS_MODULE=config.settings.test python manage.py test apps.musicians --verbosity=2
"""
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from apps.musicians.models import MusicGenre, MusicianFollower, MusicianProfile, MusicianReview, MusicalWork
from tests.factories import (
    MusicGenreFactory,
    MusicianProfileFactory,
    MusicianUserFactory,
    MusicalWorkFactory,
    UserFactory,
)


class MusicGenreListTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        MusicGenreFactory.create_batch(3)

    def test_list_genres_public(self):
        response = self.client.get("/api/v1/musicians/genres/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 3)


class MusicianProfileCreateTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = MusicianUserFactory()
        self.genre = MusicGenreFactory()
        self.url = "/api/v1/musicians/"

    def _auth(self, user=None):
        self.client.force_authenticate(user=user or self.user)

    def test_create_profile_authenticated(self):
        self._auth()
        data = {
            "artistic_name": "Los Volcanes",
            "aggregation_type": "BANDA",
            "city": "Pasto",
            "region": "Narino",
            "contact_email": "volcanes@test.com",
            "genre_ids": [self.genre.pk],
        }
        response = self.client.post(self.url, data, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["artistic_name"], "Los Volcanes")
        self.assertIn("slug", response.data)
        self.assertTrue(MusicianProfile.objects.filter(user=self.user).exists())

    def test_cannot_create_duplicate_profile(self):
        self._auth()
        MusicianProfileFactory(user=self.user)
        data = {"artistic_name": "Otro Nombre", "aggregation_type": "SOLISTA", "city": "Pasto"}
        response = self.client.post(self.url, data, format="json")
        self.assertEqual(response.status_code, 400)

    def test_unauthenticated_cannot_create(self):
        data = {"artistic_name": "Test", "aggregation_type": "SOLISTA"}
        response = self.client.post(self.url, data, format="json")
        self.assertEqual(response.status_code, 401)


class MusicianProfileListTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.active_profiles = MusicianProfileFactory.create_batch(3, is_active=True)
        MusicianProfileFactory(is_active=False)

    def test_list_only_active_profiles(self):
        response = self.client.get("/api/v1/musicians/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 3)

    def test_filter_by_aggregation_type(self):
        MusicianProfileFactory(aggregation_type="BANDA", is_active=True)
        response = self.client.get("/api/v1/musicians/?aggregation_type=BANDA")
        self.assertEqual(response.status_code, 200)
        for result in response.data["results"]:
            self.assertEqual(result["aggregation_type"], "BANDA")

    def test_filter_by_city(self):
        MusicianProfileFactory(city="Ipiales", is_active=True)
        response = self.client.get("/api/v1/musicians/?city=Ipiales")
        self.assertEqual(response.status_code, 200)
        for result in response.data["results"]:
            self.assertEqual(result["city"], "Ipiales")

    def test_filter_by_genre_slug(self):
        genre = MusicGenreFactory(name="Rock", slug="rock")
        profile = MusicianProfileFactory(is_active=True)
        profile.genres.add(genre)
        response = self.client.get("/api/v1/musicians/?genre=rock")
        self.assertEqual(response.status_code, 200)
        ids = [r["id"] for r in response.data["results"]]
        self.assertIn(str(profile.id), ids)

    def test_search_by_name(self):
        MusicianProfileFactory(artistic_name="Chaskis del Galeras", is_active=True)
        response = self.client.get("/api/v1/musicians/?search=Galeras")
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(response.data["count"], 1)


class MusicianProfileDetailTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.profile = MusicianProfileFactory(is_active=True)

    def test_retrieve_profile_by_slug(self):
        response = self.client.get(f"/api/v1/musicians/{self.profile.slug}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["artistic_name"], self.profile.artistic_name)

    def test_update_own_profile(self):
        self.client.force_authenticate(user=self.profile.user)
        response = self.client.patch(
            f"/api/v1/musicians/{self.profile.slug}/",
            {"bio": "Nueva bio actualizada"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["bio"], "Nueva bio actualizada")

    def test_cannot_update_others_profile(self):
        other_user = UserFactory()
        self.client.force_authenticate(user=other_user)
        response = self.client.patch(
            f"/api/v1/musicians/{self.profile.slug}/",
            {"bio": "Intento malicioso"},
            format="json",
        )
        self.assertEqual(response.status_code, 404)


class FollowMusicianTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.profile = MusicianProfileFactory(is_active=True, followers_count=0)
        self.user = UserFactory()
        self.url = f"/api/v1/musicians/{self.profile.slug}/follow/"

    def test_follow_musician(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, 201)
        self.assertTrue(
            MusicianFollower.objects.filter(user=self.user, musician=self.profile).exists()
        )
        self.profile.refresh_from_db()
        self.assertEqual(self.profile.followers_count, 1)

    def test_unfollow_musician(self):
        self.client.force_authenticate(user=self.user)
        MusicianFollower.objects.create(user=self.user, musician=self.profile)
        MusicianProfile.objects.filter(pk=self.profile.pk).update(followers_count=1)
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertFalse(
            MusicianFollower.objects.filter(user=self.user, musician=self.profile).exists()
        )
        self.profile.refresh_from_db()
        self.assertEqual(self.profile.followers_count, 0)

    def test_cannot_follow_own_profile(self):
        self.client.force_authenticate(user=self.profile.user)
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, 400)

    def test_follow_requires_authentication(self):
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, 401)


class MusicalWorkTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.profile = MusicianProfileFactory(is_active=True)

    def test_list_works_public(self):
        MusicalWorkFactory.create_batch(2, musician=self.profile)
        response = self.client.get(f"/api/v1/musicians/{self.profile.slug}/works/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 2)

    def test_add_work_to_own_profile(self):
        self.client.force_authenticate(user=self.profile.user)
        data = {
            "title": "Mi primer video",
            "work_type": "VIDEO",
            "youtube_url": "https://youtube.com/watch?v=abc123",
        }
        response = self.client.post(
            f"/api/v1/musicians/{self.profile.slug}/works/add/", data, format="json"
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(MusicalWork.objects.filter(musician=self.profile).count(), 1)

    def test_cannot_add_work_to_others_profile(self):
        other_user = UserFactory()
        self.client.force_authenticate(user=other_user)
        data = {"title": "Intento", "work_type": "VIDEO", "youtube_url": "https://youtube.com"}
        response = self.client.post(
            f"/api/v1/musicians/{self.profile.slug}/works/add/", data, format="json"
        )
        self.assertEqual(response.status_code, 403)

    def test_filter_works_by_type(self):
        MusicalWorkFactory(musician=self.profile, work_type="VIDEO")
        MusicalWorkFactory(musician=self.profile, work_type="LIVE")
        response = self.client.get(
            f"/api/v1/musicians/{self.profile.slug}/works/?type=VIDEO"
        )
        self.assertEqual(response.status_code, 200)
        for work in response.data:
            self.assertEqual(work["work_type"], "VIDEO")


class MusicianReviewTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.profile = MusicianProfileFactory(is_active=True)
        self.reviewer = UserFactory()

    def test_leave_review(self):
        self.client.force_authenticate(user=self.reviewer)
        data = {"rating": 5, "comment": "Excelente músico de Pasto!"}
        response = self.client.post(
            f"/api/v1/musicians/{self.profile.slug}/reviews/", data, format="json"
        )
        self.assertEqual(response.status_code, 201)
        self.assertTrue(
            MusicianReview.objects.filter(musician=self.profile, reviewer=self.reviewer).exists()
        )

    def test_cannot_review_own_profile(self):
        self.client.force_authenticate(user=self.profile.user)
        data = {"rating": 5, "comment": "Yo mismo me califico"}
        response = self.client.post(
            f"/api/v1/musicians/{self.profile.slug}/reviews/", data, format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_cannot_leave_duplicate_review(self):
        self.client.force_authenticate(user=self.reviewer)
        MusicianReview.objects.create(
            musician=self.profile, reviewer=self.reviewer, rating=4
        )
        data = {"rating": 3, "comment": "Segunda opinion"}
        response = self.client.post(
            f"/api/v1/musicians/{self.profile.slug}/reviews/", data, format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_list_reviews_public(self):
        MusicianReview.objects.create(musician=self.profile, reviewer=self.reviewer, rating=5)
        response = self.client.get(f"/api/v1/musicians/{self.profile.slug}/reviews/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)


class MusicDiscoveryTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        genre = MusicGenreFactory(name="Rock Alternativo", slug="rock-alternativo")
        self.profile = MusicianProfileFactory(city="Pasto", is_active=True)
        self.profile.genres.add(genre)

    def test_recommendations_requires_query(self):
        response = self.client.post("/api/v1/music-discovery/recommendations/", {}, format="json")
        self.assertEqual(response.status_code, 400)

    def test_recommendations_genre_filter(self):
        response = self.client.post(
            "/api/v1/music-discovery/recommendations/",
            {"query": "músicos de rock alternativo"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)
        self.assertIn("filters_applied", response.data)

    def test_recommendations_city_filter(self):
        response = self.client.post(
            "/api/v1/music-discovery/recommendations/",
            {"query": "bandas de pasto nariño"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        filters = response.data["filters_applied"]
        self.assertEqual(filters.get("city"), "Pasto")

    def test_recommendations_public_no_auth_required(self):
        response = self.client.post(
            "/api/v1/music-discovery/recommendations/",
            {"query": "salsa"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)

    def test_recommendations_me_endpoint(self):
        user = MusicianUserFactory()
        self.client.force_authenticate(user=user)
        MusicianProfileFactory(user=user)
        response = self.client.get("/api/v1/musicians/me/")
        self.assertEqual(response.status_code, 200)

    def test_recommendations_me_no_profile(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get("/api/v1/musicians/me/")
        self.assertEqual(response.status_code, 404)
