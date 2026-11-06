from decimal import Decimal

from django.db import connection
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APITestCase

from apps.marketplace.models import CartItem, Favorite, Order, OrderItem
from services.marketplace_service import MarketplaceService
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class SellerSalesTests(APITestCase):
    """Mis ventas: cada artista ve solo sus obras de la orden y su subtotal."""

    def setUp(self):
        self.ana = ArtistProfileFactory(artistic_name="Ana Pintora")
        self.luis = ArtistProfileFactory(artistic_name="Luis Escultor")
        self.buyer = UserFactory()
        self.ana_work = ArtworkFactory(artist=self.ana, title="Volcán", main_image_url="https://img.test/volcan.jpg")
        self.luis_work = ArtworkFactory(artist=self.luis, title="Carnaval")
        self.order = Order.objects.create(buyer=self.buyer, total_amount=Decimal("300000.00"), status=Order.Status.PAGADO)
        OrderItem.objects.create(order=self.order, artwork=self.ana_work, price=Decimal("100000.00"))
        OrderItem.objects.create(order=self.order, artwork=self.luis_work, price=Decimal("200000.00"))

    def sales_for(self, profile):
        self.client.force_authenticate(user=profile.user)
        return results(self.client.get("/api/v1/marketplace/sales/"))

    def test_each_artist_sees_only_their_items_and_subtotal(self):
        (ana_sale,) = self.sales_for(self.ana)
        self.assertEqual([i["artwork_title"] for i in ana_sale["items"]], ["Volcán"])
        self.assertEqual(Decimal(ana_sale["seller_amount"]), Decimal("100000.00"))
        (luis_sale,) = self.sales_for(self.luis)
        self.assertEqual([i["artwork_title"] for i in luis_sale["items"]], ["Carnaval"])
        self.assertEqual(Decimal(luis_sale["seller_amount"]), Decimal("200000.00"))

    def test_total_amount_is_unchanged(self):
        (sale,) = self.sales_for(self.ana)
        self.assertEqual(Decimal(sale["total_amount"]), Decimal("300000.00"))

    def test_items_expose_artist_and_image(self):
        (sale,) = self.sales_for(self.ana)
        item = sale["items"][0]
        self.assertEqual(item["artist_name"], "Ana Pintora")
        self.assertEqual(item["artist_slug"], self.ana.slug)
        self.assertEqual(item["artwork_image_url"], "https://img.test/volcan.jpg")

    def test_unpaid_orders_are_not_sales(self):
        Order.objects.filter(id=self.order.id).update(status=Order.Status.PENDIENTE)
        self.assertEqual(self.sales_for(self.ana), [])

    def test_buyer_orders_still_show_every_item(self):
        self.client.force_authenticate(user=self.buyer)
        (order,) = results(self.client.get("/api/v1/marketplace/orders/"))
        self.assertEqual({i["artist_name"] for i in order["items"]}, {"Ana Pintora", "Luis Escultor"})


class CartAndFavoriteCardsTests(APITestCase):
    """Carrito y favoritos traen lo necesario para pintar la tarjeta de la obra."""

    def setUp(self):
        self.user = UserFactory()
        self.artist = ArtistProfileFactory(artistic_name="Ana Pintora")
        self.client.force_authenticate(user=self.user)

    def test_favorites_include_card_fields_and_keep_old_keys(self):
        work = ArtworkFactory(artist=self.artist, title="Volcán", price="150000.00", main_image_url="https://img.test/v.jpg")
        Favorite.objects.create(user=self.user, artwork=work)
        (fav,) = self.client.get("/api/v1/marketplace/favorites/").data
        self.assertEqual(fav["artwork_id"], str(work.id))
        self.assertEqual(fav["title"], "Volcán")
        self.assertEqual(fav["artwork_title"], "Volcán")
        self.assertEqual(Decimal(fav["artwork_price"]), Decimal("150000.00"))
        self.assertEqual(fav["artwork_status"], "DISPONIBLE")
        self.assertEqual(fav["artwork_image_url"], "https://img.test/v.jpg")
        self.assertEqual(fav["artist_name"], "Ana Pintora")

    def test_cart_items_include_image_and_artist(self):
        work = ArtworkFactory(artist=self.artist, main_image_url="https://img.test/c.jpg")
        MarketplaceService.add_to_cart(user=self.user, artwork_id=work.id)
        (item,) = self.client.get("/api/v1/marketplace/cart/").data["items"]
        self.assertEqual(item["artist_name"], "Ana Pintora")
        self.assertEqual(item["artwork_image_url"], "https://img.test/c.jpg")

    def test_favorites_query_count_is_constant(self):
        Favorite.objects.create(user=self.user, artwork=ArtworkFactory(artist=self.artist))
        with CaptureQueriesContext(connection) as one:
            self.client.get("/api/v1/marketplace/favorites/")
        for _ in range(4):
            Favorite.objects.create(user=self.user, artwork=ArtworkFactory(artist=ArtistProfileFactory()))
        with CaptureQueriesContext(connection) as five:
            self.client.get("/api/v1/marketplace/favorites/")
        self.assertEqual(len(one), len(five))

    def test_cart_query_count_is_constant(self):
        MarketplaceService.add_to_cart(user=self.user, artwork_id=ArtworkFactory(artist=self.artist).id)
        with CaptureQueriesContext(connection) as one:
            self.client.get("/api/v1/marketplace/cart/")
        cart = MarketplaceService.get_or_create_cart(user=self.user)
        for _ in range(4):
            CartItem.objects.create(cart=cart, artwork=ArtworkFactory(artist=ArtistProfileFactory()))
        with CaptureQueriesContext(connection) as five:
            self.client.get("/api/v1/marketplace/cart/")
        self.assertEqual(len(one), len(five))
