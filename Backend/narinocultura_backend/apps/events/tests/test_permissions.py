from django.contrib.auth.models import AnonymousUser
from rest_framework.test import APIRequestFactory, APITestCase

from apps.events.models import Event
from apps.events.permissions import IsEventManagerOrReadOnly
from apps.notifications.models import NotificationLog
from tests.factories import (
    AdminUserFactory,
    ArtistUserFactory,
    CulturalManagerFactory,
    EventFactory,
    UserFactory,
)

URL = "/api/v1/events/"


class EventEditPermissionApiTests(APITestCase):
    """Quién puede editar o eliminar un evento: su organizador o un administrador."""

    def setUp(self):
        self.manager = CulturalManagerFactory()
        self.artist = ArtistUserFactory()
        self.admin = AdminUserFactory()
        self.published = EventFactory(organizer=self.manager)
        self.artist_event = EventFactory(organizer=self.artist, is_published=False)

    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def _url(self, event):
        return f"{URL}{event.id}/"

    # --- organizador ----------------------------------------------------------

    def test_manager_edits_own_event(self):
        r = self.as_user(self.manager).patch(self._url(self.published), {"location": "Casona Taminango"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.published.refresh_from_db()
        self.assertEqual(self.published.location, "Casona Taminango")

    def test_artist_deletes_own_pending_event(self):
        self.assertEqual(self.as_user(self.artist).delete(self._url(self.artist_event)).status_code, 204)
        self.assertFalse(Event.objects.filter(id=self.artist_event.id).exists())

    def test_manager_publishing_own_draft_notifies(self):
        draft = EventFactory(organizer=self.manager, is_published=False)
        r = self.as_user(self.manager).patch(self._url(draft), {"is_published": True}, format="json")
        self.assertEqual(r.status_code, 200)
        log = NotificationLog.objects.get(notification_type="EVENT_PUBLISHED")
        self.assertEqual(log.payload["event_id"], str(draft.id))

    def test_editing_without_publishing_does_not_notify(self):
        self.as_user(self.manager).patch(self._url(self.published), {"title": "Otro título"}, format="json")
        self.assertFalse(NotificationLog.objects.filter(notification_type="EVENT_PUBLISHED").exists())

    def test_manager_creates_published_event(self):
        data = {
            "title": "Festival de luz",
            "description": "Muestra de faroles",
            "event_type": "FERIA",
            "start_date": self.published.start_date.isoformat(),
            "end_date": self.published.end_date.isoformat(),
            "is_published": True,
        }
        r = self.as_user(self.manager).post(URL, data, format="json")
        self.assertEqual(r.status_code, 201)
        event = Event.objects.get(id=r.data["id"])
        self.assertTrue(event.is_published)
        self.assertEqual(event.organizer, self.manager)

    # --- administrador --------------------------------------------------------

    def test_admin_edits_any_event(self):
        r = self.as_user(self.admin).patch(self._url(self.artist_event), {"title": "Revisado"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.artist_event.refresh_from_db()
        self.assertEqual(self.artist_event.title, "Revisado")

    def test_admin_deletes_any_event(self):
        self.assertEqual(self.as_user(self.admin).delete(self._url(self.published)).status_code, 204)
        self.assertFalse(Event.objects.filter(id=self.published.id).exists())

    # --- terceros -------------------------------------------------------------

    def test_other_manager_cannot_edit_foreign_event(self):
        r = self.as_user(CulturalManagerFactory()).patch(self._url(self.artist_event), {"title": "X"}, format="json")
        self.assertEqual(r.status_code, 403)
        self.artist_event.refresh_from_db()
        self.assertNotEqual(self.artist_event.title, "X")

    def test_other_artist_cannot_delete_published_event(self):
        self.assertEqual(self.as_user(ArtistUserFactory()).delete(self._url(self.published)).status_code, 403)
        self.assertTrue(Event.objects.filter(id=self.published.id).exists())

    def test_other_artist_does_not_see_foreign_draft(self):
        r = self.as_user(ArtistUserFactory()).patch(self._url(self.artist_event), {"title": "X"}, format="json")
        self.assertEqual(r.status_code, 404)

    def test_buyer_cannot_edit_or_delete(self):
        buyer = UserFactory()
        self.assertEqual(self.as_user(buyer).patch(self._url(self.published), {"title": "X"}, format="json").status_code, 403)
        self.assertEqual(self.as_user(buyer).delete(self._url(self.published)).status_code, 403)

    def test_anonymous_cannot_edit_or_delete(self):
        self.assertEqual(self.client.patch(self._url(self.published), {"title": "X"}, format="json").status_code, 401)
        self.assertEqual(self.client.delete(self._url(self.published)).status_code, 401)
        self.assertTrue(Event.objects.filter(id=self.published.id).exists())


class IsEventManagerOrReadOnlyTests(APITestCase):
    """Reglas del permiso aisladas de la vista (la lectura de la vista usa AllowAny + filtro de queryset)."""

    def setUp(self):
        self.permission = IsEventManagerOrReadOnly()
        self.organizer = ArtistUserFactory()
        self.published = EventFactory(organizer=self.organizer)
        self.draft = EventFactory(organizer=self.organizer, is_published=False)

    def _request(self, method, user):
        request = getattr(APIRequestFactory(), method)("/")
        request.user = user
        return request

    def _can_access(self, method, user, event):
        return self.permission.has_object_permission(self._request(method, user), None, event)

    def test_anyone_may_read_safely(self):
        self.assertTrue(self.permission.has_permission(self._request("get", AnonymousUser()), None))

    def test_only_manager_roles_may_write(self):
        self.assertFalse(self.permission.has_permission(self._request("post", AnonymousUser()), None))
        self.assertFalse(self.permission.has_permission(self._request("post", UserFactory()), None))
        for user in (self.organizer, CulturalManagerFactory(), AdminUserFactory()):
            self.assertTrue(self.permission.has_permission(self._request("post", user), None))

    def test_published_event_is_readable_by_anyone(self):
        self.assertTrue(self._can_access("get", AnonymousUser(), self.published))

    def test_draft_is_readable_only_by_organizer_or_admin(self):
        self.assertFalse(self._can_access("get", AnonymousUser(), self.draft))
        self.assertFalse(self._can_access("get", ArtistUserFactory(), self.draft))
        self.assertFalse(self._can_access("get", CulturalManagerFactory(), self.draft))
        self.assertTrue(self._can_access("get", self.organizer, self.draft))
        self.assertTrue(self._can_access("get", AdminUserFactory(), self.draft))

    def test_write_is_reserved_to_organizer_or_admin(self):
        self.assertFalse(self._can_access("patch", AnonymousUser(), self.published))
        self.assertFalse(self._can_access("delete", CulturalManagerFactory(), self.published))
        self.assertFalse(self._can_access("patch", ArtistUserFactory(), self.published))
        self.assertTrue(self._can_access("patch", self.organizer, self.published))
        self.assertTrue(self._can_access("delete", AdminUserFactory(), self.published))
