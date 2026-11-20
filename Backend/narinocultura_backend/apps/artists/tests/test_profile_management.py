"""Creación y edición del perfil de artista: reglas de rol, slug único, imagen y estadísticas."""
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APITestCase

from apps.artists.models import ArtistProfile, Follow
from apps.artists.serializers import ArtistProfileSerializer, ArtistProfileSummarySerializer
from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory

URL = "/api/v1/artists/"


def upload(name="perfil.jpg"):
    return SimpleUploadedFile(name, b"contenido-de-imagen", content_type="image/jpeg")


class ArtistProfileCreateTests(APITestCase):
    def setUp(self):
        self.artist_user = ArtistUserFactory()
        self.client.force_authenticate(user=self.artist_user)

    def test_artist_creates_profile_with_generated_slug_and_stats(self):
        r = self.client.post(URL, {"artistic_name": "Taller Andino", "city": "Pasto"}, format="json")
        self.assertEqual(r.status_code, 201)
        profile = ArtistProfile.objects.get(user=self.artist_user)
        self.assertEqual(profile.slug, "taller-andino")
        self.assertEqual(r.data["slug"], "taller-andino")
        # El perfil recién creado no viene anotado: las estadísticas se calculan en el serializer
        self.assertEqual(r.data["following_count"], 0)
        self.assertFalse(r.data["is_following"])
        self.assertEqual(r.data["artworks_count"], 0)
        self.assertEqual(r.data["profile_image_url"], "")

    def test_slug_gets_suffix_when_name_is_taken(self):
        ArtistProfileFactory(slug="taller-andino")
        ArtistProfileFactory(slug="taller-andino-2")
        r = self.client.post(URL, {"artistic_name": "Taller Andino"}, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["slug"], "taller-andino-3")

    def test_slug_falls_back_when_name_has_no_letters(self):
        r = self.client.post(URL, {"artistic_name": "¡¡¡!!!"}, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["slug"], "artista")

    def test_artist_cannot_create_a_second_profile(self):
        ArtistProfileFactory(user=self.artist_user)
        r = self.client.post(URL, {"artistic_name": "Otro"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("Este usuario ya tiene un perfil de artista.", r.data["non_field_errors"])
        self.assertEqual(ArtistProfile.objects.filter(user=self.artist_user).count(), 1)

    def test_buyer_cannot_create_profile(self):
        buyer = UserFactory()
        self.client.force_authenticate(user=buyer)
        r = self.client.post(URL, {"artistic_name": "Comprador"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("Solo un usuario con rol ARTISTA puede crear perfil.", r.data["non_field_errors"])
        self.assertFalse(ArtistProfile.objects.filter(user=buyer).exists())

    def test_anonymous_cannot_create_profile(self):
        self.client.force_authenticate(user=None)
        r = self.client.post(URL, {"artistic_name": "Anónimo"}, format="json")
        self.assertEqual(r.status_code, 401)


class ArtistProfileUpdateTests(APITestCase):
    def setUp(self):
        self.profile = ArtistProfileFactory(slug="mi-taller")
        self.client.force_authenticate(user=self.profile.user)
        self.url = f"{URL}{self.profile.slug}/"

    def test_owner_updates_profile_and_slug_stays(self):
        r = self.client.patch(self.url, {"bio": "Ceramista de Pasto", "slug": "otro"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.profile.refresh_from_db()
        self.assertEqual(self.profile.bio, "Ceramista de Pasto")
        self.assertEqual(self.profile.slug, "mi-taller")

    def test_uploaded_profile_image_is_returned_as_absolute_url(self):
        r = self.client.patch(self.url, {"profile_image": upload()}, format="multipart")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["profile_image_url"].startswith("http://testserver/"))
        self.assertIn("artists/profiles/", r.data["profile_image_url"])

    def test_patch_does_not_trigger_creation_rules(self):
        # Las reglas de rol solo aplican a POST: un artista que cambió de rol aún puede editar
        self.profile.user.role = "COMPRADOR"
        self.profile.user.save()
        r = self.client.patch(self.url, {"city": "Ipiales"}, format="json")
        self.assertEqual(r.status_code, 200)

    def test_other_user_cannot_update_profile(self):
        self.client.force_authenticate(user=UserFactory())
        r = self.client.patch(self.url, {"bio": "Hackeado"}, format="json")
        self.assertEqual(r.status_code, 404)

    def test_owner_deletes_profile(self):
        r = self.client.delete(self.url)
        self.assertEqual(r.status_code, 204)
        self.assertFalse(ArtistProfile.objects.filter(id=self.profile.id).exists())


class FollowingAvatarTests(APITestCase):
    def test_following_list_includes_absolute_avatar(self):
        artist = ArtistProfileFactory(profile_image=upload())
        plain = ArtistProfileFactory()
        fan = UserFactory()
        Follow.objects.create(follower=fan, artist=artist)
        Follow.objects.create(follower=fan, artist=plain)
        self.client.force_authenticate(user=fan)
        r = self.client.get(f"{URL}following/")
        avatars = {row["slug"]: row["avatar_url"] for row in r.data}
        self.assertTrue(avatars[artist.slug].startswith("http://testserver/"))
        self.assertEqual(avatars[plain.slug], "")


class ArtistSerializerWithoutRequestTests(TestCase):
    """Uso del serializer fuera de una vista (tareas, correos): sin request ni anotaciones."""

    def setUp(self):
        self.profile = ArtistProfileFactory(profile_image=upload())
        ArtworkFactory(artist=self.profile, status="DISPONIBLE")
        ArtworkFactory(artist=self.profile, status="INACTIVA")
        Follow.objects.create(follower=self.profile.user, artist=ArtistProfileFactory())

    def test_stats_are_computed_and_urls_are_relative(self):
        data = ArtistProfileSerializer(self.profile).data
        self.assertEqual(data["artworks_count"], 1)
        self.assertEqual(data["following_count"], 1)
        self.assertFalse(data["is_following"])
        self.assertFalse(data["profile_image_url"].startswith("http"))
        self.assertIn("artists/profiles/", data["profile_image_url"])
        summary = ArtistProfileSummarySerializer(self.profile).data
        self.assertEqual(summary["avatar_url"], data["profile_image_url"])

    def test_str_representations(self):
        follow = Follow.objects.get(follower=self.profile.user)
        self.assertEqual(str(self.profile), self.profile.artistic_name)
        self.assertEqual(str(follow), f"{follow.follower_id} -> {follow.artist_id}")
