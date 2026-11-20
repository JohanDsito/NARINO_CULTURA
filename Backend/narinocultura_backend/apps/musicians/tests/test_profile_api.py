"""API de músicos: imágenes de perfil, géneros, obras propias y reseñas."""
from django.contrib.auth.models import AnonymousUser
from rest_framework.test import APIRequestFactory, APITestCase

from apps.musicians.models import MusicalWork, MusicianFollower, MusicianProfile, MusicianReview
from apps.musicians.serializers import (
    MusicianProfileListSerializer,
    MusicianProfileSerializer,
    MusicianProfileSummarySerializer,
    MusicianReviewSerializer,
)
from tests.factories import (
    MusicalWorkFactory,
    MusicGenreFactory,
    MusicianProfileFactory,
    MusicianUserFactory,
    UserFactory,
)

BASE = "/api/v1/musicians/"
IMAGE = "musicians/profiles/volcanes.jpg"


class ProfileImageUrlTests(APITestCase):
    """La imagen de perfil se expone como URL absoluta (o relativa sin request) y vacía si no hay."""

    def setUp(self):
        self.profile = MusicianProfileFactory(profile_image=IMAGE)
        self.request = APIRequestFactory().get("/")
        self.request.user = AnonymousUser()

    def test_serializers_build_relative_url_without_request(self):
        self.assertEqual(MusicianProfileSerializer(self.profile).data["profile_image_url"], f"/media/{IMAGE}")
        self.assertEqual(MusicianProfileListSerializer(self.profile).data["profile_image_url"], f"/media/{IMAGE}")
        self.assertEqual(MusicianProfileSummarySerializer(self.profile).data["avatar_url"], f"/media/{IMAGE}")

    def test_serializers_build_absolute_url_with_request(self):
        context = {"request": self.request}
        expected = f"http://testserver/media/{IMAGE}"
        self.assertEqual(MusicianProfileSerializer(self.profile, context=context).data["profile_image_url"], expected)
        self.assertEqual(MusicianProfileListSerializer(self.profile, context=context).data["profile_image_url"], expected)
        self.assertEqual(MusicianProfileSummarySerializer(self.profile, context=context).data["avatar_url"], expected)

    def test_profile_without_image_has_empty_urls(self):
        profile = MusicianProfileFactory()
        self.assertEqual(MusicianProfileSerializer(profile).data["profile_image_url"], "")
        self.assertEqual(MusicianProfileListSerializer(profile).data["profile_image_url"], "")
        self.assertEqual(MusicianProfileSummarySerializer(profile).data["avatar_url"], "")

    def test_list_detail_and_following_endpoints_return_absolute_url(self):
        follower = UserFactory()
        MusicianFollower.objects.create(user=follower, musician=self.profile)
        self.client.force_authenticate(user=follower)
        expected = f"http://testserver/media/{IMAGE}"

        listing = self.client.get(BASE)
        self.assertEqual(listing.data["results"][0]["profile_image_url"], expected)
        detail = self.client.get(f"{BASE}{self.profile.slug}/")
        self.assertEqual(detail.data["profile_image_url"], expected)
        self.assertTrue(detail.data["is_following"])
        following = self.client.get(f"{BASE}following/")
        self.assertEqual(following.data[0]["avatar_url"], expected)


class ProfileGenresTests(APITestCase):
    def setUp(self):
        self.user = MusicianUserFactory()
        self.client.force_authenticate(user=self.user)

    def test_create_without_genres(self):
        response = self.client.post(BASE, {"artistic_name": "Solo Voz", "city": "Ipiales"}, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["genres"], [])
        self.assertEqual(response.data["works_count"], 0)

    def test_update_replaces_genres_and_keeps_them_when_omitted(self):
        profile = MusicianProfileFactory(user=self.user)
        rock, salsa = MusicGenreFactory(), MusicGenreFactory()
        profile.genres.add(rock)

        response = self.client.patch(f"{BASE}{profile.slug}/", {"genre_ids": [salsa.pk]}, format="json")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual([g["id"] for g in response.data["genres"]], [salsa.pk])

        response = self.client.patch(f"{BASE}{profile.slug}/", {"bio": "Nueva bio"}, format="json")
        self.assertEqual(response.data["bio"], "Nueva bio")
        self.assertEqual(list(profile.genres.values_list("pk", flat=True)), [salsa.pk])


class OwnMusicalWorksTests(APITestCase):
    """/musicians/works/ gestiona solo las obras del músico autenticado."""

    URL = f"{BASE}works/"

    def setUp(self):
        self.profile = MusicianProfileFactory()
        self.client.force_authenticate(user=self.profile.user)

    def test_lists_only_own_works(self):
        own = MusicalWorkFactory(musician=self.profile)
        MusicalWorkFactory()  # de otro músico
        response = self.client.get(self.URL)
        self.assertEqual(response.status_code, 200)
        items = response.data["results"] if isinstance(response.data, dict) else response.data
        self.assertEqual([w["id"] for w in items], [str(own.id)])

    def test_create_assigns_the_authenticated_musician(self):
        response = self.client.post(
            self.URL, {"title": "Galeras en vivo", "work_type": "LIVE", "musician": "ignorado"}, format="json"
        )
        self.assertEqual(response.status_code, 201, response.data)
        work = MusicalWork.objects.get(id=response.data["id"])
        self.assertEqual(work.musician, self.profile)

    def test_register_view_increments_counter(self):
        work = MusicalWorkFactory(musician=self.profile, views_count=2)
        response = self.client.post(f"{self.URL}{work.id}/view/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["detail"], "Vista registrada.")
        work.refresh_from_db()
        self.assertEqual(work.views_count, 3)

    def test_requires_authentication(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get(self.URL).status_code, 401)


class MusicianReviewApiTests(APITestCase):
    def setUp(self):
        self.profile = MusicianProfileFactory()
        self.url = f"{BASE}{self.profile.slug}/reviews/"

    def test_anonymous_cannot_post_review(self):
        response = self.client.post(self.url, {"rating": 5}, format="json")
        self.assertEqual(response.status_code, 401)
        self.assertFalse(MusicianReview.objects.exists())

    def test_reviewer_name_falls_back_to_email(self):
        reviewer = UserFactory(first_name="", last_name="")
        MusicianReview.objects.create(musician=self.profile, reviewer=reviewer, rating=4)
        response = self.client.get(self.url)
        self.assertEqual(response.data[0]["reviewer_name"], reviewer.email)

    def test_social_stats_are_computed_without_annotations(self):
        reviewer = UserFactory()
        MusicianReview.objects.create(musician=self.profile, reviewer=reviewer, rating=4)
        MusicianReview.objects.create(musician=self.profile, reviewer=UserFactory(), rating=5)
        profile = MusicianProfile.objects.get(pk=self.profile.pk)
        data = MusicianProfileListSerializer(profile).data
        self.assertEqual(data["average_rating"], 4.5)
        self.assertEqual(data["reviews_count"], 2)
        self.assertFalse(data["is_following"])

    def test_review_serializer_without_musician_context_only_validates_fields(self):
        serializer = MusicianReviewSerializer(data={"rating": 3, "comment": "Bien"})
        self.assertTrue(serializer.is_valid(), serializer.errors)
        invalid = MusicianReviewSerializer(data={"rating": 9})
        self.assertFalse(invalid.is_valid())
        self.assertIn("rating", invalid.errors)
