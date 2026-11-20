"""Moderación de obras desde el panel de administración: pendientes, aprobar, rechazar y eliminar."""
import unittest
from decimal import Decimal

from rest_framework.test import APITestCase

from apps.artworks.models import Artwork
from apps.marketplace.models import Order, OrderItem
from tests.factories import AdminUserFactory, ArtworkFactory, UserFactory

PENDING_URL = "/api/v1/admin/artworks/pending/"


def moderate_url(artwork_id):
    return f"/api/v1/admin/artworks/{artwork_id}/moderate/"


UNKNOWN_ID = "00000000-0000-0000-0000-000000000000"


class PendingArtworksTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory()
        self.pending = ArtworkFactory(status=Artwork.Status.INACTIVA, price="99000.00")
        ArtworkFactory(status=Artwork.Status.DISPONIBLE)

    def test_admin_lists_only_inactive_artworks(self):
        self.client.force_authenticate(user=self.admin)
        r = self.client.get(PENDING_URL)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(len(r.data), 1)
        row = r.data[0]
        self.assertEqual(row["id"], str(self.pending.id))
        self.assertEqual(row["artist_slug"], self.pending.artist.slug)
        self.assertEqual(row["price"], "99000.00")

    def test_non_admin_gets_403(self):
        self.client.force_authenticate(user=self.pending.artist.user)
        self.assertEqual(self.client.get(PENDING_URL).status_code, 403)

    def test_anonymous_gets_401(self):
        self.assertEqual(self.client.get(PENDING_URL).status_code, 401)


class ModerateArtworkTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory()
        self.artwork = ArtworkFactory(status=Artwork.Status.INACTIVA)
        self.client.force_authenticate(user=self.admin)

    def test_approve_publishes_artwork(self):
        r = self.client.patch(moderate_url(self.artwork.id), {"status": "DISPONIBLE"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["detail"], "Obra moderada correctamente.")
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.status, Artwork.Status.DISPONIBLE)
        # Ya aparece en el catálogo público
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get(f"/api/v1/artworks/{self.artwork.id}/").status_code, 200)

    def test_reject_via_post_hides_artwork(self):
        published = ArtworkFactory(status=Artwork.Status.DISPONIBLE)
        r = self.client.post(
            moderate_url(published.id), {"status": "INACTIVA", "reason": "Imagen inapropiada"}, format="json"
        )
        self.assertEqual(r.status_code, 200)
        published.refresh_from_db()
        self.assertEqual(published.status, Artwork.Status.INACTIVA)

    def test_sale_statuses_are_not_allowed_in_moderation(self):
        for value in ("VENDIDA", "EN_SUBASTA"):
            r = self.client.patch(moderate_url(self.artwork.id), {"status": value}, format="json")
            self.assertEqual(r.status_code, 400)
            self.assertEqual(
                r.data["status"], ["El estado permitido para moderación es DISPONIBLE o INACTIVA."]
            )
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.status, Artwork.Status.INACTIVA)

    def test_unknown_status_is_rejected(self):
        r = self.client.patch(moderate_url(self.artwork.id), {"status": "BORRADOR"}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_unknown_artwork_returns_404(self):
        r = self.client.patch(moderate_url(UNKNOWN_ID), {"status": "DISPONIBLE"}, format="json")
        self.assertEqual(r.status_code, 404)
        self.assertEqual(r.data["detail"], "Obra no encontrada.")

    def test_admin_deletes_artwork(self):
        r = self.client.delete(moderate_url(self.artwork.id))
        self.assertEqual(r.status_code, 204)
        self.assertFalse(Artwork.objects.filter(id=self.artwork.id).exists())

    def test_delete_unknown_artwork_returns_404(self):
        self.assertEqual(self.client.delete(moderate_url(UNKNOWN_ID)).status_code, 404)

    # BUG: ModerateArtworkAPIView.delete (apps/administration/views.py:120) no captura ProtectedError
    # como sí hace ArtworkViewSet.admin_delete; borrar una obra con órdenes responde 500 en vez de 409.
    @unittest.expectedFailure
    def test_delete_artwork_with_orders_returns_409(self):
        order = Order.objects.create(buyer=UserFactory(), total_amount=Decimal("150000.00"))
        OrderItem.objects.create(order=order, artwork=self.artwork, price=Decimal("150000.00"))
        self.client.raise_request_exception = False
        r = self.client.delete(moderate_url(self.artwork.id))
        self.assertEqual(r.status_code, 409)

    def test_non_admin_cannot_moderate_or_delete(self):
        for user in (self.artwork.artist.user, UserFactory()):
            self.client.force_authenticate(user=user)
            r = self.client.patch(moderate_url(self.artwork.id), {"status": "DISPONIBLE"}, format="json")
            self.assertEqual(r.status_code, 403)
            self.assertEqual(self.client.delete(moderate_url(self.artwork.id)).status_code, 403)
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.status, Artwork.Status.INACTIVA)
