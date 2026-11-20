"""Afiches subidos como archivo: lectura con IA, guardado y creación de eventos con imagen."""
from datetime import timedelta
from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import SimpleTestCase, override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.events.models import Event
from tests import llm_fakes
from tests.factories import ArtistUserFactory, CulturalManagerFactory, EventFactory
from utils.media import sniff_image_type

PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 64
JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 64
EXTRACT_URL = "/api/v1/events/extract-from-flyer/"


def png(name="afiche.png", data=PNG, content_type="image/png"):
    return SimpleUploadedFile(name, data, content_type=content_type)


class ImageSniffingTests(SimpleTestCase):
    def test_detects_supported_formats_by_content(self):
        self.assertEqual(sniff_image_type(PNG), "image/png")
        self.assertEqual(sniff_image_type(JPEG), "image/jpeg")
        self.assertEqual(sniff_image_type(b"RIFF\x00\x00\x00\x00WEBPVP8 "), "image/webp")
        self.assertEqual(sniff_image_type(b"\x00\x00\x00\x18ftypheic\x00\x00"), "image/heic")
        self.assertIsNone(sniff_image_type(b"%PDF-1.7"))
        self.assertIsNone(sniff_image_type(b"<svg xmlns='http://www.w3.org/2000/svg'/>"))


@override_settings(**llm_fakes.KEYS)
class FlyerUploadExtractionTests(APITestCase):
    def setUp(self):
        self.manager = CulturalManagerFactory()
        self.client.force_authenticate(user=self.manager)

    @patch("services.ai_service.requests.get")
    @patch("services.llm._session.post")
    def test_uploaded_flyer_goes_to_gemini_and_is_stored(self, post, download):
        post.return_value = llm_fakes.gemini(
            {"title": "Festival Andino", "event_type": "CONCIERTO", "start_date": "2030-12-12T16:00:00-05:00"}
        )
        r = self.client.post(EXTRACT_URL, {"flyer": png()}, format="multipart")

        self.assertEqual(r.status_code, 200)
        suggested = r.data["suggested_event"]
        self.assertEqual((suggested["title"], suggested["source"]), ("Festival Andino", "ai_service"))
        # La imagen se envía tal cual a Gemini, sin descargarla de ninguna URL
        download.assert_not_called()
        part = post.call_args.kwargs["json"]["contents"][-1]["parts"][1]["inline_data"]
        self.assertEqual(part["mime_type"], "image/png")
        # Y queda guardada para usarla en el formulario o en el borrador
        self.assertRegex(suggested["image_url"], r"^https?://.+/events/flyers/[0-9a-f]{32}\.png$")

    @patch("services.llm._session.post")
    def test_draft_from_uploaded_flyer_keeps_the_image(self, post):
        post.return_value = llm_fakes.gemini(
            {"title": "Feria", "event_type": "FERIA", "start_date": "2030-12-12T10:00:00-05:00"}
        )
        r = self.client.post(EXTRACT_URL, {"flyer": png(), "create_draft": True}, format="multipart")
        self.assertEqual(r.status_code, 200)
        event = Event.objects.get(id=r.data["event"]["id"])
        self.assertTrue(event.image_url.endswith(".png"))
        self.assertFalse(event.is_published)

    @override_settings(GEMINI_API_KEY="", GROQ_API_KEY="")
    def test_without_ai_the_flyer_is_still_stored(self):
        r = self.client.post(EXTRACT_URL, {"flyer": png(), "flyer_text": "Taller de cerámica"}, format="multipart")
        suggested = r.data["suggested_event"]
        self.assertEqual((suggested["source"], suggested["event_type"]), ("heuristic", "TALLER"))
        self.assertTrue(suggested["image_url"].endswith(".png"))

    def test_rejects_files_that_are_not_images_even_with_image_extension(self):
        r = self.client.post(EXTRACT_URL, {"flyer": png("afiche.png", b"%PDF-1.7 ...", "image/png")}, format="multipart")
        self.assertEqual(r.status_code, 400)
        self.assertIn("flyer", r.data)

    @patch("apps.events.serializers.FLYER_MAX_BYTES", 32)
    def test_rejects_files_over_the_size_limit(self):
        r = self.client.post(EXTRACT_URL, {"flyer": png()}, format="multipart")
        self.assertEqual(r.status_code, 400)
        self.assertIn("5 MB", str(r.data["flyer"]))

    def test_needs_some_input(self):
        r = self.client.post(EXTRACT_URL, {}, format="multipart")
        self.assertEqual(r.status_code, 400)


class EventCreateWithFlyerTests(APITestCase):
    """La web envía el afiche como archivo ``flyer`` al crear el evento; antes se ignoraba."""

    def payload(self, **extra):
        start = timezone.now() + timedelta(days=10)
        return {
            "title": "Noche andina",
            "description": "Música en vivo",
            "event_type": "CONCIERTO",
            "start_date": start.isoformat(),
            "end_date": (start + timedelta(hours=3)).isoformat(),
            "location": "Pasto",
            "is_published": "false",
            **extra,
        }

    def test_artist_creates_event_with_uploaded_flyer(self):
        self.client.force_authenticate(user=ArtistUserFactory())
        r = self.client.post("/api/v1/events/", self.payload(flyer=png("afiche.jpg", JPEG, "image/jpeg")), format="multipart")
        self.assertEqual(r.status_code, 201, r.data)
        self.assertNotIn("flyer", r.data)
        self.assertRegex(r.data["image_url"], r"/events/flyers/[0-9a-f]{32}\.jpg$")
        self.assertEqual(Event.objects.get(id=r.data["id"]).image_url, r.data["image_url"])

    def test_invalid_flyer_is_rejected_and_no_event_is_created(self):
        self.client.force_authenticate(user=ArtistUserFactory())
        r = self.client.post("/api/v1/events/", self.payload(flyer=png("a.png", b"no soy imagen")), format="multipart")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(Event.objects.exists())

    def test_json_with_image_url_still_works(self):
        self.client.force_authenticate(user=CulturalManagerFactory())
        data = {**self.payload(image_url="https://res.cloudinary.com/x/afiche.png"), "is_published": False}
        r = self.client.post("/api/v1/events/", data, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["image_url"], "https://res.cloudinary.com/x/afiche.png")

    def test_organizer_replaces_the_flyer_on_update(self):
        manager = CulturalManagerFactory()
        event = EventFactory(organizer=manager, image_url="https://res.cloudinary.com/x/viejo.png")
        self.client.force_authenticate(user=manager)
        r = self.client.patch(f"/api/v1/events/{event.id}/", {"flyer": png()}, format="multipart")
        self.assertEqual(r.status_code, 200, r.data)
        event.refresh_from_db()
        self.assertRegex(event.image_url, r"/events/flyers/[0-9a-f]{32}\.png$")
