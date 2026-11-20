"""Modelos de músicos: slugs, representación en texto y popularidad."""

from django.test import TestCase

from apps.musicians.models import MusicGenre, MusicianFollower, MusicianProfile, MusicianReview
from tests.factories import MusicalWorkFactory, MusicianProfileFactory, UserFactory


class MusicGenreModelTests(TestCase):
    def test_slug_is_generated_from_name_when_missing(self):
        genre = MusicGenre.objects.create(name="Música Andina")
        self.assertEqual(genre.slug, "musica-andina")
        self.assertEqual(str(genre), "Música Andina")

    def test_explicit_slug_is_kept(self):
        genre = MusicGenre.objects.create(name="Rock", slug="rock-pastuso")
        self.assertEqual(genre.slug, "rock-pastuso")


class MusicianSlugTests(TestCase):
    def test_free_slug_is_used_as_is(self):
        self.assertEqual(MusicianProfile.generate_unique_slug("Los Volcanes"), "los-volcanes")

    def test_taken_slugs_get_a_numeric_suffix(self):
        MusicianProfileFactory(slug="los-volcanes")
        self.assertEqual(MusicianProfile.generate_unique_slug("Los Volcanes"), "los-volcanes-2")
        MusicianProfileFactory(slug="los-volcanes-2")
        self.assertEqual(MusicianProfile.generate_unique_slug("Los Volcanes"), "los-volcanes-3")

    def test_name_without_slug_characters_uses_default(self):
        self.assertEqual(MusicianProfile.generate_unique_slug("¡¡!!"), "musico")


class MusicianStrTests(TestCase):
    def setUp(self):
        self.profile = MusicianProfileFactory(artistic_name="Los Volcanes")
        self.user = UserFactory()

    def test_profile_and_work(self):
        work = MusicalWorkFactory(musician=self.profile, title="Galeras")
        self.assertEqual(str(self.profile), "Los Volcanes")
        self.assertEqual(str(work), "Los Volcanes — Galeras")

    def test_follower_and_review(self):
        follower = MusicianFollower.objects.create(user=self.user, musician=self.profile)
        review = MusicianReview.objects.create(musician=self.profile, reviewer=self.user, rating=5)
        self.assertEqual(str(follower), f"{self.user.id} -> Los Volcanes")
        self.assertEqual(str(review), f"Los Volcanes — 5★ by {self.user.id}")


class RecalculatePopularityTests(TestCase):
    """La popularidad es 2 puntos por seguidor más las reproducciones de sus obras."""

    def test_score_combines_followers_and_views(self):
        profile = MusicianProfileFactory(followers_count=3)
        MusicalWorkFactory(musician=profile, views_count=10)
        MusicalWorkFactory(musician=profile, views_count=5)

        profile.recalculate_popularity()

        profile.refresh_from_db()
        self.assertEqual(profile.popularity_score, 21)

    def test_musician_without_works_scores_only_followers(self):
        profile = MusicianProfileFactory(followers_count=4)

        profile.recalculate_popularity()

        profile.refresh_from_db()
        self.assertEqual(profile.popularity_score, 8)
