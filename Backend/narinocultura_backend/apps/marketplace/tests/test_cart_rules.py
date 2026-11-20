import uuid

from rest_framework.test import APITestCase

from apps.artworks.models import Artwork
from apps.marketplace.models import Cart, CartItem, Favorite, Order, OrderItem
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory

CART_ITEMS_URL = "/api/v1/marketplace/cart/items/"
CHECKOUT_URL = "/api/v1/marketplace/checkout/"
FAVORITES_URL = "/api/v1/marketplace/favorites/"


class MarketplaceTestCase(APITestCase):
    def setUp(self):
        self.buyer = UserFactory()
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, price="90000.00")
        self.client.force_authenticate(user=self.buyer)

    def _in_cart(self, *artworks):
        cart, _ = Cart.objects.get_or_create(user=self.buyer)
        for artwork in artworks:
            CartItem.objects.create(cart=cart, artwork=artwork)
        return cart


class CartRulesTests(MarketplaceTestCase):
    """HU de carrito: solo obras existentes y DISPONIBLES."""

    def test_unknown_artwork_cannot_be_added(self):
        r = self.client.post(CART_ITEMS_URL, {"artwork_id": str(uuid.uuid4())}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("no existe", r.data["detail"])
        self.assertFalse(CartItem.objects.exists())

    def test_unavailable_artwork_cannot_be_added(self):
        reserved = ArtworkFactory(artist=self.profile, status=Artwork.Status.EN_SUBASTA)
        r = self.client.post(CART_ITEMS_URL, {"artwork_id": str(reserved.id)}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("no está disponible", r.data["detail"])
        self.assertFalse(CartItem.objects.exists())

    def test_removing_artwork_not_in_cart_fails(self):
        r = self.client.delete(CART_ITEMS_URL, {"artwork_id": str(self.artwork.id)}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("no está en el carrito", r.data["detail"])


class CheckoutRulesTests(MarketplaceTestCase):
    """Checkout: crea la orden PENDIENTE, reserva las obras y vacía el carrito."""

    def test_checkout_reserves_artworks_and_empties_cart(self):
        second = ArtworkFactory(artist=self.profile, price="10000.00")
        self._in_cart(self.artwork, second)
        r = self.client.post(CHECKOUT_URL, {}, format="json")
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.data["total_amount"], "100000.00")
        order = Order.objects.get(id=r.data["order_id"])
        self.assertEqual(order.status, Order.Status.PENDIENTE)
        self.assertEqual(order.buyer, self.buyer)
        self.assertEqual(set(order.items.values_list("artwork_id", flat=True)), {self.artwork.id, second.id})
        self.assertFalse(Artwork.objects.filter(id__in=[self.artwork.id, second.id]).exclude(status=Artwork.Status.INACTIVA).exists())
        self.assertFalse(CartItem.objects.exists())

    def test_empty_cart_cannot_checkout(self):
        r = self.client.post(CHECKOUT_URL, {}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("vacío", r.data["detail"])
        self.assertFalse(Order.objects.exists())

    def test_checkout_fails_if_an_artwork_was_sold_meanwhile(self):
        sold_meanwhile = ArtworkFactory(artist=self.profile)
        self._in_cart(self.artwork, sold_meanwhile)
        Artwork.objects.filter(id=sold_meanwhile.id).update(status=Artwork.Status.VENDIDA)
        r = self.client.post(CHECKOUT_URL, {}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(Order.objects.exists())
        # Nada se reserva y el carrito queda intacto para que el comprador lo revise
        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.status, Artwork.Status.DISPONIBLE)
        self.assertEqual(CartItem.objects.count(), 2)

    def test_invalid_order_type_is_rejected(self):
        self._in_cart(self.artwork)
        r = self.client.post(CHECKOUT_URL, {"order_type": "TRUEQUE"}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertFalse(Order.objects.exists())


class FavoriteRulesTests(MarketplaceTestCase):
    def test_duplicate_favorite_is_rejected(self):
        Favorite.objects.create(user=self.buyer, artwork=self.artwork)
        r = self.client.post(FAVORITES_URL, {"artwork_id": str(self.artwork.id)}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertEqual(Favorite.objects.count(), 1)

    def test_removing_missing_favorite_fails(self):
        r = self.client.delete(FAVORITES_URL, {"artwork_id": str(self.artwork.id)}, format="json")
        self.assertEqual(r.status_code, 400)

    def test_removing_does_not_touch_other_users_favorites(self):
        other = UserFactory()
        Favorite.objects.create(user=other, artwork=self.artwork)
        r = self.client.delete(FAVORITES_URL, {"artwork_id": str(self.artwork.id)}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertTrue(Favorite.objects.filter(user=other).exists())


class MarketplaceStrTests(MarketplaceTestCase):
    def test_models_have_readable_representation(self):
        cart = self._in_cart(self.artwork)
        item = cart.items.get()
        favorite = Favorite.objects.create(user=self.buyer, artwork=self.artwork)
        order = Order.objects.create(buyer=self.buyer, total_amount="90000.00")
        order_item = OrderItem.objects.create(order=order, artwork=self.artwork, price="90000.00")
        self.assertIn(str(self.buyer.id), str(cart))
        self.assertIn(str(self.artwork.id), str(item))
        self.assertIn(str(self.artwork.id), str(favorite))
        self.assertIn("PENDIENTE", str(order))
        self.assertIn(str(order.id), str(order_item))
