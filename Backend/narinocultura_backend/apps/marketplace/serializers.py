
from decimal import Decimal

from rest_framework import serializers

from apps.marketplace.models import Cart, CartItem, Favorite, Order, OrderItem


def artwork_image_url(artwork, request) -> str:
    """URL absoluta de la imagen principal de la obra (archivo subido o URL externa)."""
    if artwork.main_image:
        url = artwork.main_image.url
        return request.build_absolute_uri(url) if request else url
    return artwork.main_image_url or ""


class ArtworkSummaryFieldsMixin(serializers.Serializer):
    """Datos de la obra para mostrar la tarjeta sin otra consulta: imagen y artista."""

    artwork_image_url = serializers.SerializerMethodField()
    artist_name = serializers.CharField(source="artwork.artist.artistic_name", read_only=True)
    artist_slug = serializers.CharField(source="artwork.artist.slug", read_only=True)

    def get_artwork_image_url(self, obj) -> str:
        return artwork_image_url(obj.artwork, self.context.get("request"))


class CartItemSerializer(ArtworkSummaryFieldsMixin, serializers.ModelSerializer):
    artwork_title = serializers.CharField(source="artwork.title", read_only=True)
    artwork_price = serializers.DecimalField(source="artwork.price", max_digits=12, decimal_places=2, read_only=True)
    artwork_status = serializers.CharField(source="artwork.status", read_only=True)

    class Meta:
        model = CartItem
        fields = (
            "id", "artwork", "artwork_title", "artwork_price", "artwork_status",
            "artwork_image_url", "artist_name", "artist_slug", "created_at",
        )
        read_only_fields = fields


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)

    class Meta:
        model = Cart
        fields = ("id", "user", "items", "created_at", "updated_at")
        read_only_fields = ("id", "user", "items", "created_at", "updated_at")


class CartItemAddSerializer(serializers.Serializer):
    artwork_id = serializers.UUIDField()


class FavoriteSerializer(ArtworkSummaryFieldsMixin, serializers.ModelSerializer):
    artwork_title = serializers.CharField(source="artwork.title", read_only=True)
    artwork_price = serializers.DecimalField(source="artwork.price", max_digits=12, decimal_places=2, read_only=True)
    artwork_status = serializers.CharField(source="artwork.status", read_only=True)
    # Claves anteriores, que la web y la app ya leen
    artwork_id = serializers.UUIDField(source="artwork.id", read_only=True)
    title = serializers.CharField(source="artwork.title", read_only=True)

    class Meta:
        model = Favorite
        fields = (
            "id", "artwork", "artwork_id", "title", "artwork_title", "artwork_price", "artwork_status",
            "artwork_image_url", "artist_name", "artist_slug", "created_at",
        )
        read_only_fields = fields


class FavoriteToggleSerializer(serializers.Serializer):
    artwork_id = serializers.UUIDField()


class OrderItemSerializer(ArtworkSummaryFieldsMixin, serializers.ModelSerializer):
    artwork_title = serializers.CharField(source="artwork.title", read_only=True)

    class Meta:
        model = OrderItem
        fields = ("id", "artwork", "artwork_title", "artwork_image_url", "artist_name", "artist_slug", "price")
        read_only_fields = fields


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = ("id", "buyer", "total_amount", "status", "order_type", "payment_due_at", "items", "created_at")
        read_only_fields = fields


class SaleSerializer(serializers.ModelSerializer):
    """Venta vista por un artista: solo sus obras de la orden y su subtotal.

    `items` y `seller_amount` salen de `seller_items`, un prefetch filtrado por artista
    (SalesAPIView). `total_amount` sigue siendo el total de la orden completa."""

    items = OrderItemSerializer(source="seller_items", many=True, read_only=True)
    seller_amount = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ("id", "buyer", "total_amount", "seller_amount", "status", "order_type", "items", "created_at")
        read_only_fields = fields

    def get_seller_amount(self, obj) -> str:
        return str(sum((item.price for item in obj.seller_items), Decimal("0.00")))


class CheckoutSerializer(serializers.Serializer):
    order_type = serializers.ChoiceField(choices=Order.Type.choices, default=Order.Type.COMPRA_DIRECTA)

    def validate(self, attrs):
        order_type = attrs["order_type"]
        if order_type not in {Order.Type.COMPRA_DIRECTA, Order.Type.SUBASTA}:
            raise serializers.ValidationError("Tipo de orden inválido.")
        return attrs


class CheckoutResultSerializer(serializers.Serializer):
    order_id = serializers.UUIDField()
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)

