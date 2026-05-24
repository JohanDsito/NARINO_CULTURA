from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import AccessToken

from apps.marketplace.models import Cart, CartItem, Favorite, Order
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory


def auth_header(user):
    token = AccessToken.for_user(user)
    return {"HTTP_AUTHORIZATION": f"Bearer {token}"}


class CartTests(APITestCase):
    def setUp(self):
        self.user = UserFactory(role="COMPRADOR")
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")

    def test_get_cart_creates_if_not_exists(self):
        r = self.client.get("/api/v1/marketplace/cart/", **auth_header(self.user))
        self.assertEqual(r.status_code, 200)
        self.assertTrue(Cart.objects.filter(user=self.user).exists())

    def test_add_item_to_cart(self):
        r = self.client.post(
            "/api/v1/marketplace/cart/items/",
            {"artwork_id": str(self.artwork.id)},
            format="json",
            **auth_header(self.user),
        )
        self.assertIn(r.status_code, [200, 201])
        self.assertTrue(CartItem.objects.filter(cart__user=self.user, artwork=self.artwork).exists())

    def test_duplicate_item_in_cart_fails(self):
        cart = Cart.objects.create(user=self.user)
        CartItem.objects.create(cart=cart, artwork=self.artwork)
        r = self.client.post(
            "/api/v1/marketplace/cart/items/",
            {"artwork_id": str(self.artwork.id)},
            format="json",
            **auth_header(self.user),
        )
        self.assertIn(r.status_code, [400, 409])

    def test_remove_item_from_cart(self):
        cart = Cart.objects.create(user=self.user)
        CartItem.objects.create(cart=cart, artwork=self.artwork)
        r = self.client.delete(
            "/api/v1/marketplace/cart/items/",
            {"artwork_id": str(self.artwork.id)},
            format="json",
            **auth_header(self.user),
        )
        self.assertIn(r.status_code, [200, 204])
        self.assertFalse(CartItem.objects.filter(cart=cart, artwork=self.artwork).exists())

    def test_unauthenticated_cart_returns_401(self):
        r = self.client.get("/api/v1/marketplace/cart/")
        self.assertEqual(r.status_code, 401)


class FavoriteTests(APITestCase):
    def setUp(self):
        self.user = UserFactory()
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")

    def test_add_favorite(self):
        r = self.client.post(
            "/api/v1/marketplace/favorites/",
            {"artwork_id": str(self.artwork.id)},
            format="json",
            **auth_header(self.user),
        )
        self.assertIn(r.status_code, [200, 201])
        self.assertTrue(Favorite.objects.filter(user=self.user, artwork=self.artwork).exists())

    def test_list_favorites(self):
        Favorite.objects.create(user=self.user, artwork=self.artwork)
        r = self.client.get("/api/v1/marketplace/favorites/", **auth_header(self.user))
        self.assertEqual(r.status_code, 200)
        self.assertGreaterEqual(len(r.data.get("results", r.data)), 1)

    def test_remove_favorite(self):
        Favorite.objects.create(user=self.user, artwork=self.artwork)
        r = self.client.delete(
            "/api/v1/marketplace/favorites/",
            {"artwork_id": str(self.artwork.id)},
            format="json",
            **auth_header(self.user),
        )
        self.assertIn(r.status_code, [200, 204])
        self.assertFalse(Favorite.objects.filter(user=self.user, artwork=self.artwork).exists())


class OrderTests(APITestCase):
    def setUp(self):
        self.buyer = UserFactory(role="COMPRADOR")
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")

    def test_my_orders_returns_only_own_orders(self):
        Order.objects.create(buyer=self.buyer, total_amount="150000.00")
        other_user = UserFactory()
        Order.objects.create(buyer=other_user, total_amount="50000.00")

        r = self.client.get("/api/v1/marketplace/orders/", **auth_header(self.buyer))
        self.assertEqual(r.status_code, 200)
        results = r.data.get("results", r.data)
        for order in results:
            self.assertEqual(order.get("buyer") or self.buyer.id, self.buyer.id)
