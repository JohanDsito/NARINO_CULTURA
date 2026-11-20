"""Validaciones y escritura anidada del serializer de obras (precio, galería, imágenes)."""
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APITestCase

from apps.artworks.models import Artwork, ArtworkImage
from apps.artworks.serializers import ArtworkImageSerializer, ArtworkSerializer
from tests.factories import ArtistProfileFactory, ArtworkFactory

URL = "/api/v1/artworks/"


def upload(name="obra.jpg"):
    return SimpleUploadedFile(name, b"contenido-de-imagen", content_type="image/jpeg")


class ArtworkCreatePayloadTests(APITestCase):
    def setUp(self):
        self.profile = ArtistProfileFactory()
        self.client.force_authenticate(user=self.profile.user)

    def test_negative_price_is_rejected(self):
        r = self.client.post(URL, {"title": "Barata", "price": "-1"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.data["price"], ["El precio no puede ser negativo."])
        self.assertFalse(Artwork.objects.filter(title="Barata").exists())

    def test_create_with_gallery_creates_images(self):
        r = self.client.post(
            URL,
            {"title": "Con galería", "price": "1000", "images": [{"order": 1}, {"order": 2}]},
            format="json",
        )
        self.assertEqual(r.status_code, 201)
        artwork = Artwork.objects.get(id=r.data["id"])
        self.assertEqual(list(artwork.images.values_list("order", flat=True)), [1, 2])

    def test_uploaded_main_image_is_returned_as_absolute_url(self):
        r = self.client.post(
            URL, {"title": "Con portada", "price": "1000", "main_image": upload()}, format="multipart"
        )
        self.assertEqual(r.status_code, 201)
        self.assertTrue(r.data["main_image_url"].startswith("http://testserver/"))
        self.assertIn("artworks/covers/", r.data["main_image_url"])

    def test_without_main_image_falls_back_to_external_url(self):
        artwork = ArtworkFactory(artist=self.profile, main_image_url="https://cdn.test/obra.jpg")
        r = self.client.get(f"{URL}{artwork.id}/")
        self.assertEqual(r.data["main_image_url"], "https://cdn.test/obra.jpg")


class ArtworkUpdatePayloadTests(APITestCase):
    def setUp(self):
        self.artwork = ArtworkFactory()
        ArtworkImage.objects.create(artwork=self.artwork, order=0, image_url="https://cdn.test/vieja.jpg")
        self.client.force_authenticate(user=self.artwork.artist.user)
        self.url = f"{URL}{self.artwork.id}/"

    def test_sending_images_replaces_the_gallery(self):
        r = self.client.patch(self.url, {"images": [{"order": 5}]}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(list(self.artwork.images.values_list("order", flat=True)), [5])

    def test_omitting_images_keeps_the_gallery(self):
        r = self.client.patch(self.url, {"title": "Renombrada"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.title, "Renombrada")
        self.assertEqual(self.artwork.images.count(), 1)

    def test_negative_price_on_update_is_rejected(self):
        r = self.client.patch(self.url, {"price": "-500"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.artwork.refresh_from_db()
        self.assertEqual(str(self.artwork.price), "150000.00")


class ArtworkImageUrlTests(APITestCase):
    def setUp(self):
        self.artwork = ArtworkFactory()

    def test_gallery_urls_cover_uploaded_external_and_missing_images(self):
        ArtworkImage.objects.create(artwork=self.artwork, order=0, image=upload("g.jpg"))
        ArtworkImage.objects.create(artwork=self.artwork, order=1, image_url="https://cdn.test/ext.jpg")
        ArtworkImage.objects.create(artwork=self.artwork, order=2)
        r = self.client.get(f"{URL}{self.artwork.id}/")
        urls = [img["image_url"] for img in r.data["images"]]
        self.assertTrue(urls[0].startswith("http://testserver/"))
        self.assertIn("artworks/gallery/", urls[0])
        self.assertEqual(urls[1:], ["https://cdn.test/ext.jpg", ""])

    def test_without_request_urls_are_relative(self):
        image = ArtworkImage.objects.create(artwork=self.artwork, order=0, image=upload("g.jpg"))
        self.artwork.main_image = upload("portada.jpg")
        self.artwork.save()
        self.assertFalse(ArtworkImageSerializer(image).data["image_url"].startswith("http"))
        self.assertFalse(ArtworkSerializer(self.artwork).data["main_image_url"].startswith("http"))
