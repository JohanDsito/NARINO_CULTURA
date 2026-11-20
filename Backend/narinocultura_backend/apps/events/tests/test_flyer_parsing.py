from datetime import datetime
from unittest.mock import MagicMock, patch
from zoneinfo import ZoneInfo

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.events.models import Event, EventRegistration
from services.event_service import EventService
from tests.factories import CulturalManagerFactory, EventFactory, UserFactory

BOGOTA = ZoneInfo("America/Bogota")


class FlyerDateParsingTests(TestCase):
    """HU de flyers: lectura heurística de fecha y hora en español."""

    def test_pm_hour_is_converted_to_24h(self):
        start = EventService._extract_start_date("5 de marzo de 2031 a las 7:30 p.m.")
        self.assertEqual((start.year, start.month, start.day, start.hour, start.minute), (2031, 3, 5, 19, 30))

    def test_twelve_am_is_midnight(self):
        self.assertEqual(EventService._extract_start_date("1 de enero de 2031 12 am").hour, 0)

    def test_twelve_pm_is_noon(self):
        self.assertEqual(EventService._extract_start_date("1 de enero de 2031 12 pm").hour, 12)

    def test_morning_hour_is_kept(self):
        self.assertEqual(EventService._extract_start_date("8 de agosto de 2031 9 a.m.").hour, 9)

    def test_without_time_defaults_to_seven_pm(self):
        start = EventService._extract_start_date("20 de julio de 2031")
        self.assertEqual((start.hour, start.minute), (19, 0))

    def test_setiembre_spelling_is_accepted(self):
        self.assertEqual(EventService._extract_start_date("10 de setiembre de 2031").month, 9)

    def test_unknown_month_returns_none(self):
        self.assertIsNone(EventService._extract_start_date("10 de brumario de 2031"))

    def test_text_without_date_returns_none(self):
        self.assertIsNone(EventService._extract_start_date("Gran concierto sin fecha"))
        self.assertIsNone(EventService._extract_start_date(""))

    def test_past_date_without_year_moves_to_next_year(self):
        fake_now = datetime(2030, 6, 1, 12, 0, tzinfo=BOGOTA)
        with patch("services.event_service.datetime", wraps=datetime) as mocked:
            mocked.now.return_value = fake_now
            start = EventService._extract_start_date("3 de febrero 8 pm")
        self.assertEqual((start.year, start.month, start.day), (2031, 2, 3))

    def test_past_date_with_explicit_year_is_kept(self):
        start = EventService._extract_start_date("3 de febrero de 2020 8 pm")
        self.assertEqual(start.year, 2020)

    def test_impossible_date_is_ignored(self):
        self.assertIsNone(EventService._extract_start_date("31 de febrero de 2031 8 pm"))


class FlyerTextParsingTests(TestCase):
    def test_location_is_empty_without_text(self):
        self.assertEqual(EventService._extract_location(""), "")

    def test_location_is_empty_when_not_mentioned(self):
        self.assertEqual(EventService._extract_location("Gran concierto 2031"), "")

    def test_event_type_falls_back_to_otro(self):
        self.assertEqual(EventService._infer_event_type("Reunión comunitaria"), Event.Type.OTRO)

    def test_event_type_detects_workshop(self):
        self.assertEqual(EventService._infer_event_type("Masterclass de guitarra"), "TALLER")

    def test_empty_flyer_gets_generic_title(self):
        data = EventService._heuristic_extract(image_url="https://img.test/f.png", flyer_text="")
        self.assertEqual(data["title"], "Evento cultural")
        self.assertIsNone(data["start_date"])
        self.assertIsNone(data["end_date"])
        self.assertEqual(data["image_url"], "https://img.test/f.png")


@override_settings(AI_SERVICE_URL="http://ai.local")
class AiExtractionNormalizationTests(TestCase):
    """La respuesta del microservicio de IA se completa y se sanea antes de llegar al cliente."""

    def setUp(self):
        self.manager = CulturalManagerFactory()

    @patch("services.event_service.requests.post")
    def test_unknown_event_type_becomes_otro(self, post):
        post.return_value = MagicMock(content=b"{}", json=lambda: {"title": "Rave", "event_type": "RAVE", "location": None})
        data = EventService.extract_from_flyer(organizer=self.manager, flyer_text="Rave")
        self.assertEqual(data["event_type"], Event.Type.OTRO)
        self.assertEqual(data["location"], "")
        self.assertEqual(data["source"], "ai_service")

    @patch("services.event_service.requests.post")
    def test_empty_ai_response_yields_blank_suggestion(self, post):
        post.return_value = MagicMock(content=b"")
        data = EventService.extract_from_flyer(organizer=self.manager, flyer_text="Texto")
        self.assertEqual(data["title"], "")
        self.assertEqual(data["raw_text"], "Texto")
        self.assertFalse(data["is_published"])

    @patch("services.event_service.requests.post")
    def test_manager_keeps_published_flag_from_ai(self, post):
        post.return_value = MagicMock(content=b"{}", json=lambda: {"title": "Feria", "is_published": True})
        data = EventService.extract_from_flyer(organizer=self.manager, flyer_text="Feria")
        self.assertTrue(data["is_published"])

    def test_non_dict_ai_payload_is_normalized(self):
        self.assertEqual(EventService._normalize_ai_extraction(["no", "dict"])["event_type"], Event.Type.OTRO)


class EventRegistrationsApiTests(TestCase):
    def test_registered_user_sees_flag_and_str_is_readable(self):
        user = UserFactory()
        event = EventFactory(organizer=CulturalManagerFactory(), title="Carnaval")
        registration = EventRegistration.objects.create(event=event, user=user)
        client = APIClient()
        client.force_authenticate(user=user)
        r = client.get(f"/api/v1/events/{event.id}/")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["is_registered"])
        self.assertEqual(str(event), "Carnaval")
        self.assertIn(str(user.id), str(registration))
