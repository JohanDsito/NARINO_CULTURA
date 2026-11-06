from apps.artists.models import ArtistProfile, Follow
from rest_framework.test import APITestCase
from tests.factories import ArtistProfileFactory, UserFactory


class ArtistFollowTests(APITestCase):
    def setUp(self):
        self.artist = ArtistProfileFactory()
        self.fan = UserFactory(first_name="Ana", last_name="Pérez")

    def test_follow_other_artist(self):
        self.client.force_authenticate(user=self.fan)
        r = self.client.post(f"/api/v1/artists/{self.artist.slug}/follow/")
        self.assertEqual(r.status_code, 201)
        self.assertTrue(Follow.objects.filter(follower=self.fan, artist=self.artist).exists())
        self.artist.refresh_from_db()
        self.assertEqual(self.artist.followers_count, 1)

    def test_follow_twice_unfollows(self):
        self.client.force_authenticate(user=self.fan)
        self.client.post(f"/api/v1/artists/{self.artist.slug}/follow/")
        r = self.client.post(f"/api/v1/artists/{self.artist.slug}/follow/")
        self.assertEqual(r.status_code, 200)
        self.assertFalse(Follow.objects.filter(follower=self.fan, artist=self.artist).exists())
        self.artist.refresh_from_db()
        self.assertEqual(self.artist.followers_count, 0)

    def test_cannot_follow_own_profile(self):
        self.client.force_authenticate(user=self.artist.user)
        r = self.client.post(f"/api/v1/artists/{self.artist.slug}/follow/")
        self.assertEqual(r.status_code, 400)

    def test_cannot_follow_private_profile(self):
        private = ArtistProfileFactory(is_public=False)
        self.client.force_authenticate(user=self.fan)
        r = self.client.post(f"/api/v1/artists/{private.slug}/follow/")
        self.assertEqual(r.status_code, 404)

    def test_follow_requires_authentication(self):
        r = self.client.post(f"/api/v1/artists/{self.artist.slug}/follow/")
        self.assertEqual(r.status_code, 401)


class ArtistFollowersListTests(APITestCase):
    def setUp(self):
        self.artist = ArtistProfileFactory()
        self.fan = UserFactory(first_name="Ana", last_name="Pérez")
        Follow.objects.create(follower=self.fan, artist=self.artist)

    def test_owner_sees_followers(self):
        self.client.force_authenticate(user=self.artist.user)
        r = self.client.get(f"/api/v1/artists/{self.artist.slug}/followers/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.data), 1)
        item = r.data[0]
        self.assertEqual(item["id"], str(self.fan.id))
        self.assertEqual(item["first_name"], "Ana")
        self.assertEqual(item["avatar_url"], "")
        self.assertNotIn("email", item)

    def test_other_user_cannot_see_followers(self):
        self.client.force_authenticate(user=self.fan)
        r = self.client.get(f"/api/v1/artists/{self.artist.slug}/followers/")
        self.assertEqual(r.status_code, 404)

    def test_followers_requires_authentication(self):
        r = self.client.get(f"/api/v1/artists/{self.artist.slug}/followers/")
        self.assertEqual(r.status_code, 401)


class ArtistFollowingListTests(APITestCase):
    def setUp(self):
        self.fan = UserFactory()
        self.followed = ArtistProfileFactory()
        self.not_followed = ArtistProfileFactory()
        Follow.objects.create(follower=self.fan, artist=self.followed)

    def test_lists_followed_artists(self):
        self.client.force_authenticate(user=self.fan)
        r = self.client.get("/api/v1/artists/following/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual([a["slug"] for a in r.data], [self.followed.slug])
        self.assertEqual(r.data[0]["artistic_name"], self.followed.artistic_name)

    def test_hides_artists_that_became_private(self):
        ArtistProfile.objects.filter(id=self.followed.id).update(is_public=False)
        self.client.force_authenticate(user=self.fan)
        r = self.client.get("/api/v1/artists/following/")
        self.assertEqual(r.data, [])

    def test_following_requires_authentication(self):
        r = self.client.get("/api/v1/artists/following/")
        self.assertEqual(r.status_code, 401)
