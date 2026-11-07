import uuid
from decimal import Decimal

from rest_framework.test import APITestCase

from apps.marketplace.models import Order, OrderItem
from tests.factories import AdminUserFactory, ArtistProfileFactory, ArtworkFactory, UserFactory


class OrderDetailTests(APITestCase):
    """GET /marketplace/orders/{id}/ (pedido de la app móvil)."""

    def setUp(self):
        self.buyer = UserFactory()
        artist = ArtistProfileFactory(artistic_name="Ana Pintora")
        self.order = Order.objects.create(buyer=self.buyer, total_amount=Decimal("80000.00"))
        OrderItem.objects.create(order=self.order, artwork=ArtworkFactory(artist=artist, title="Volcán"), price=Decimal("80000.00"))
        self.url = f"/api/v1/marketplace/orders/{self.order.id}/"

    def test_buyer_sees_own_order_with_items(self):
        self.client.force_authenticate(user=self.buyer)
        r = self.client.get(self.url)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["id"], str(self.order.id))
        self.assertEqual(r.data["status"], "PENDIENTE")
        (item,) = r.data["items"]
        self.assertEqual(item["artwork_title"], "Volcán")
        self.assertEqual(item["artist_name"], "Ana Pintora")

    def test_same_shape_as_the_orders_list(self):
        self.client.force_authenticate(user=self.buyer)
        listed = self.client.get("/api/v1/marketplace/orders/").data
        listed = listed["results"] if isinstance(listed, dict) else listed
        self.assertEqual(set(self.client.get(self.url).data), set(listed[0]))

    def test_other_users_get_404(self):
        self.client.force_authenticate(user=UserFactory())
        self.assertEqual(self.client.get(self.url).status_code, 404)

    def test_admin_can_see_any_order(self):
        self.client.force_authenticate(user=AdminUserFactory())
        self.assertEqual(self.client.get(self.url).status_code, 200)

    def test_unknown_order_and_anonymous(self):
        self.client.force_authenticate(user=self.buyer)
        self.assertEqual(self.client.get(f"/api/v1/marketplace/orders/{uuid.uuid4()}/").status_code, 404)
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get(self.url).status_code, 401)
