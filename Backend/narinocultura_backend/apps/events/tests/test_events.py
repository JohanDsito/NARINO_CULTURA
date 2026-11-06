from datetime import timedelta
from unittest.mock import MagicMock, patch

import requests
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.events.models import Event, EventRegistration
from apps.notifications.models import NotificationLog
from tests.factories import (
    AdminUserFactory,
    ArtistUserFactory,
    CulturalManagerFactory,
    EventFactory,
    UserFactory,
)

URL = "/api/v1/events/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class EventTestCase(APITestCase):
    def setUp(self):
        self.buyer = UserFactory()
        self.artist = ArtistUserFactory()
        self.manager = CulturalManagerFactory()
        self.admin = AdminUserFactory()
        self.published = EventFactory(organizer=self.manager)
        self.pending = EventFactory(organizer=self.artist, is_published=False)

    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def payload(self, **overrides):
        start = timezone.now() + timedelta(days=10)
        data = {
            "title": "Noche andina",
            "description": "Música andina en vivo",
            "event_type": "CONCIERTO",
            "start_date": start.isoformat(),
            "end_date": (start + timedelta(hours=3)).isoformat(),
            "location": "Pasto",
        }
        data.update(overrides)
        return data


class EventVisibilityTests(EventTestCase):
    def test_public_sees_only_published_events(self):
        r = self.client.get(URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual({e["id"] for e in results(r)}, {str(self.published.id)})
        self.assertEqual(self.client.get(f"{URL}{self.pending.id}/").status_code, 404)

    def test_artist_sees_own_pending_event(self):
        ids = {e["id"] for e in results(self.as_user(self.artist).get(URL))}
        self.assertEqual(ids, {str(self.published.id), str(self.pending.id)})

    def test_organizer_is_public_data_without_email(self):
        organizer = self.client.get(f"{URL}{self.published.id}/").data["organizer"]
        self.assertEqual(organizer["id"], str(self.manager.id))
        self.assertEqual(organizer["first_name"], self.manager.first_name)
        self.assertNotIn("email", organizer)


class EventCrudTests(EventTestCase):
    def test_artist_event_starts_unpublished(self):
        r = self.as_user(self.artist).post(URL, self.payload(), format="json")
        self.assertEqual(r.status_code, 201)
        self.assertFalse(Event.objects.get(id=r.data["id"]).is_published)

    def test_artist_cannot_self_publish(self):
        r = self.as_user(self.artist).post(URL, self.payload(is_published=True), format="json")
        self.assertEqual(r.status_code, 400)
        r = self.as_user(self.artist).patch(f"{URL}{self.pending.id}/", {"is_published": True}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_buyer_cannot_create_event(self):
        self.assertEqual(self.as_user(self.buyer).post(URL, self.payload(), format="json").status_code, 403)

    def test_anonymous_cannot_create_event(self):
        self.assertEqual(self.client.post(URL, self.payload(), format="json").status_code, 401)

    def test_end_before_start_is_rejected(self):
        start = timezone.now() + timedelta(days=3)
        data = self.payload(start_date=start.isoformat(), end_date=(start - timedelta(hours=1)).isoformat())
        self.assertEqual(self.as_user(self.manager).post(URL, data, format="json").status_code, 400)

    def test_organizer_can_edit_own_event(self):
        r = self.as_user(self.artist).patch(f"{URL}{self.pending.id}/", {"title": "Nuevo título"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.pending.refresh_from_db()
        self.assertEqual(self.pending.title, "Nuevo título")

    def test_other_artist_cannot_edit_published_event(self):
        other = ArtistUserFactory()
        r = self.as_user(other).patch(f"{URL}{self.published.id}/", {"title": "Hackeado"}, format="json")
        self.assertEqual(r.status_code, 403)

    def test_other_manager_cannot_edit_foreign_event(self):
        r = self.as_user(CulturalManagerFactory()).delete(f"{URL}{self.published.id}/")
        self.assertEqual(r.status_code, 403)
        self.assertTrue(Event.objects.filter(id=self.published.id).exists())


class EventModerationTests(EventTestCase):
    def test_admin_approves_pending_event(self):
        r = self.as_user(self.admin).post(f"{URL}{self.pending.id}/approve/")
        self.assertEqual(r.status_code, 200)
        self.pending.refresh_from_db()
        self.assertTrue(self.pending.is_published)
        self.assertTrue(NotificationLog.objects.filter(notification_type="EVENT_PUBLISHED").exists())

    def test_approving_published_event_fails(self):
        self.assertEqual(self.as_user(self.admin).post(f"{URL}{self.published.id}/approve/").status_code, 400)

    def test_non_admin_cannot_approve_or_reject(self):
        for user in (self.artist, self.manager):
            self.assertEqual(self.as_user(user).post(f"{URL}{self.pending.id}/approve/").status_code, 403)
            self.assertEqual(self.as_user(user).post(f"{URL}{self.pending.id}/reject/").status_code, 403)
        self.pending.refresh_from_db()
        self.assertFalse(self.pending.is_published)

    def test_admin_rejects_pending_event(self):
        r = self.as_user(self.admin).post(f"{URL}{self.pending.id}/reject/")
        self.assertEqual(r.status_code, 200)
        self.assertFalse(Event.objects.filter(id=self.pending.id).exists())

    def test_published_event_cannot_be_rejected(self):
        self.assertEqual(self.as_user(self.admin).post(f"{URL}{self.published.id}/reject/").status_code, 400)


class EventRegistrationTests(EventTestCase):
    """HU-B05 (RF24): cualquier usuario autenticado se inscribe en un evento publicado."""

    def register(self, user, event):
        return self.as_user(user).post(f"{URL}{event.id}/register/")

    def test_every_role_can_register_to_published_event(self):
        for user in (self.buyer, self.artist, CulturalManagerFactory(), self.admin):
            r = self.register(user, self.published)
            self.assertEqual(r.status_code, 201, user.role)
        self.assertEqual(EventRegistration.objects.filter(event=self.published).count(), 4)

    def test_registration_is_notified(self):
        self.register(self.buyer, self.published)
        log = NotificationLog.objects.get(notification_type="EVENT_REGISTRATION")
        self.assertEqual(log.payload["user_email"], self.buyer.email)
        self.assertEqual(log.payload["event_id"], str(self.published.id))

    def test_duplicate_registration_is_rejected(self):
        self.register(self.buyer, self.published)
        r = self.register(self.buyer, self.published)
        self.assertEqual(r.status_code, 400)
        self.assertEqual(EventRegistration.objects.filter(event=self.published, user=self.buyer).count(), 1)

    def test_anonymous_cannot_register(self):
        self.assertEqual(self.client.post(f"{URL}{self.published.id}/register/").status_code, 401)

    def test_cannot_register_to_unpublished_event(self):
        self.assertEqual(self.register(self.buyer, self.pending).status_code, 404)
        # El organizador sí ve su evento pendiente, pero tampoco puede inscribirse
        self.assertEqual(self.register(self.artist, self.pending).status_code, 400)
        self.assertFalse(EventRegistration.objects.exists())

    def test_cannot_register_to_finished_event(self):
        past = EventFactory(
            start_date=timezone.now() - timedelta(days=2),
            end_date=timezone.now() - timedelta(days=1),
        )
        r = self.register(self.buyer, past)
        self.assertEqual(r.status_code, 400)
        self.assertIn("finalizó", r.data["detail"])


@override_settings(AI_SERVICE_URL="")
class EventFlyerExtractionTests(EventTestCase):
    FLYER = "Concierto de música andina\nLugar: Teatro Imperial\n15 de diciembre de 2030 8:00 pm"
    EXTRACT_URL = f"{URL}extract-from-flyer/"

    def test_heuristic_extraction_without_ai_service(self):
        r = self.as_user(self.manager).post(self.EXTRACT_URL, {"flyer_text": self.FLYER}, format="json")
        self.assertEqual(r.status_code, 200)
        suggested = r.data["suggested_event"]
        self.assertEqual(suggested["source"], "heuristic")
        self.assertEqual(suggested["event_type"], "CONCIERTO")
        self.assertEqual(suggested["title"], "Concierto de música andina")
        self.assertIn("Teatro Imperial", suggested["location"])
        self.assertTrue(suggested["start_date"].startswith("2030-12-15T20:00"))
        self.assertFalse(r.data["draft_created"])

    def test_create_draft_from_flyer_is_unpublished_for_artist(self):
        data = {"flyer_text": self.FLYER, "create_draft": True}
        r = self.as_user(self.artist).post(self.EXTRACT_URL, data, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["draft_created"])
        event = Event.objects.get(id=r.data["event"]["id"])
        self.assertFalse(event.is_published)
        self.assertEqual(event.organizer, self.artist)

    def test_draft_without_date_is_rejected(self):
        data = {"flyer_text": "Taller de cerámica", "create_draft": True}
        r = self.as_user(self.manager).post(self.EXTRACT_URL, data, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(r.data["draft_created"])

    def test_empty_request_is_rejected(self):
        self.assertEqual(self.as_user(self.manager).post(self.EXTRACT_URL, {}, format="json").status_code, 400)

    def test_buyer_cannot_use_flyer_extraction(self):
        r = self.as_user(self.buyer).post(self.EXTRACT_URL, {"flyer_text": self.FLYER}, format="json")
        self.assertEqual(r.status_code, 403)

    @override_settings(AI_SERVICE_URL="http://ai.local")
    @patch("services.event_service.requests.post")
    def test_uses_ai_service_when_available(self, post):
        post.return_value = MagicMock(
            content=b"{}",
            json=lambda: {"title": "Festival", "event_type": "FERIA", "location": "Pasto", "is_published": True},
        )
        r = self.as_user(self.artist).post(self.EXTRACT_URL, {"flyer_text": self.FLYER}, format="json")
        self.assertEqual(r.status_code, 200)
        suggested = r.data["suggested_event"]
        self.assertEqual(suggested["source"], "ai_service")
        self.assertEqual(suggested["title"], "Festival")
        # Un artista nunca recibe una sugerencia publicada, aunque la IA la marque así
        self.assertFalse(suggested["is_published"])
        self.assertEqual(post.call_args.args[0], "http://ai.local/events/extract-from-flyer")

    @override_settings(AI_SERVICE_URL="http://ai.local")
    @patch("services.event_service.requests.post", side_effect=requests.ConnectionError)
    def test_falls_back_to_heuristic_when_ai_service_fails(self, _post):
        r = self.as_user(self.manager).post(self.EXTRACT_URL, {"flyer_text": self.FLYER}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["suggested_event"]["source"], "heuristic")
