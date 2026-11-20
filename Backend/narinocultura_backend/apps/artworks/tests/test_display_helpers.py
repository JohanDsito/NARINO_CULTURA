"""Representaciones visibles de obras: helpers de utils/media.py y textos del panel de Django."""
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import RequestFactory, TestCase

from apps.artworks.models import ArtworkImage, Category
from tests.factories import ArtworkFactory, UserFactory
from utils.media import artwork_image_url, public_name


class ArtworkImageUrlHelperTests(TestCase):
    def setUp(self):
        self.artwork = ArtworkFactory(main_image_url="https://cdn.test/portada.jpg")

    def test_uses_external_url_when_no_file(self):
        self.assertEqual(artwork_image_url(self.artwork), "https://cdn.test/portada.jpg")

    def test_returns_empty_string_without_any_image(self):
        self.artwork.main_image_url = ""
        self.assertEqual(artwork_image_url(self.artwork), "")

    def test_uploaded_file_wins_and_is_absolute_with_request(self):
        self.artwork.main_image = SimpleUploadedFile("p.jpg", b"img", content_type="image/jpeg")
        self.artwork.save()
        relative = artwork_image_url(self.artwork)
        self.assertIn("artworks/covers/", relative)
        absolute = artwork_image_url(self.artwork, RequestFactory().get("/"))
        self.assertEqual(absolute, f"http://testserver{relative}")


class PublicNameTests(TestCase):
    def test_first_name_and_last_initial(self):
        self.assertEqual(public_name(UserFactory.build(first_name="Ana", last_name="Pérez")), "Ana P.")

    def test_without_last_name(self):
        self.assertEqual(public_name(UserFactory.build(first_name="Ana", last_name="")), "Ana")

    def test_anonymous_fallback_when_no_names(self):
        self.assertEqual(public_name(UserFactory.build(first_name="", last_name="")), "Postor")


class ArtworkStrTests(TestCase):
    """Textos que muestra el admin de Django para identificar cada registro."""

    def test_str_representations(self):
        category = Category.objects.get(slug="pintura")
        artwork = ArtworkFactory(title="Laguna de la Cocha", category=category)
        image = ArtworkImage.objects.create(artwork=artwork, order=3)
        self.assertEqual(str(category), "Pintura")
        self.assertEqual(str(artwork), f"Laguna de la Cocha ({artwork.artist_id})")
        self.assertEqual(str(image), f"{artwork.id} - 3")
