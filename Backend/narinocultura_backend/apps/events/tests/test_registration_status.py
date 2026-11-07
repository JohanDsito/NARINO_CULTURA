from datetime import timedelta

from django.db import connection
from django.test.utils import CaptureQueriesContext
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.events.models import EventRegistration
from tests.factories import EventFactory, UserFactory

URL = "/api/v1/events/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class EventRegistrationStatusTests(APITestCase):
    """is_registered y cancelación de la inscripción (pedido de la app móvil)."""

    def setUp(self):
        self.user = UserFactory()
        self.event = EventFactory()
        self.client.force_authenticate(user=self.user)

    def register_url(self, event=None):
        return f"{URL}{(event or self.event).id}/register/"

    def test_is_registered_follows_registration(self):
        self.assertFalse(self.client.get(f"{URL}{self.event.id}/").data["is_registered"])
        self.client.post(self.register_url())
        self.assertTrue(self.client.get(f"{URL}{self.event.id}/").data["is_registered"])
        listed = next(e for e in results(self.client.get(URL)) if e["id"] == str(self.event.id))
        self.assertTrue(listed["is_registered"])

    def test_is_registered_is_false_for_anonymous(self):
        EventRegistration.objects.create(event=self.event, user=self.user)
        self.client.force_authenticate(user=None)
        self.assertFalse(self.client.get(f"{URL}{self.event.id}/").data["is_registered"])

    def test_cancel_registration(self):
        self.client.post(self.register_url())
        r = self.client.delete(self.register_url())
        self.assertEqual(r.status_code, 200)
        self.assertFalse(EventRegistration.objects.filter(event=self.event, user=self.user).exists())
        self.assertFalse(self.client.get(f"{URL}{self.event.id}/").data["is_registered"])

    def test_can_register_again_after_cancelling(self):
        self.client.post(self.register_url())
        self.client.delete(self.register_url())
        self.assertEqual(self.client.post(self.register_url()).status_code, 201)

    def test_cancel_without_registration_fails(self):
        r = self.client.delete(self.register_url())
        self.assertEqual(r.status_code, 400)
        self.assertIn("No estás inscrito", r.data["detail"])

    def test_cancel_only_affects_own_registration(self):
        other = UserFactory()
        EventRegistration.objects.create(event=self.event, user=other)
        self.assertEqual(self.client.delete(self.register_url()).status_code, 400)
        self.assertTrue(EventRegistration.objects.filter(event=self.event, user=other).exists())

    def test_cannot_cancel_after_event_ended(self):
        past = EventFactory(start_date=timezone.now() - timedelta(days=2), end_date=timezone.now() - timedelta(days=1))
        EventRegistration.objects.create(event=past, user=self.user)
        self.assertEqual(self.client.delete(self.register_url(past)).status_code, 400)
        self.assertTrue(EventRegistration.objects.filter(event=past, user=self.user).exists())

    def test_anonymous_cannot_cancel(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.delete(self.register_url()).status_code, 401)

    def test_list_query_count_does_not_grow_with_events(self):
        with CaptureQueriesContext(connection) as one:
            self.client.get(URL)
        for _ in range(4):
            EventRegistration.objects.create(event=EventFactory(), user=self.user)
        with CaptureQueriesContext(connection) as five:
            r = self.client.get(URL)
        self.assertEqual(len(results(r)), 5)
        self.assertEqual(len(one), len(five))
