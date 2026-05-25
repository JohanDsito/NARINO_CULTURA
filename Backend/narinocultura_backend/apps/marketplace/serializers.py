from decimal import Decimal

from rest_framework import serializers

from apps.marketplace.models import Cart, CartItem, Favorite, Order, OrderItem


class CartItemSerializer(serializers.ModelSerializer):
    artwork_title = serializers.CharField(source="artwork.title", read_only=True)
    artwork_price = serializers.DecimalField(source="artwork.price", max_digits=12, decimal_places=2, read_only=True)
    artwork_status = serializers.CharField(source="artwork.status", read_only=True)

    class Meta:
        model = CartItem
        fields = ("id", "artwork", "artwork_title", "artwork_price", "artwork_status", "created_at")
        read_only_fields = ("id", "created_at", "artwork_title", "artwork_price", "artwork_status")


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)

    class Meta:
        model = Cart
        fields = ("id", "user", "items", "created_at", "updated_at")
        read_only_fields = ("id", "user", "items", "created_at", "updated_at")


class CartItemAddSerializer(serializers.Serializer):
    artwork_id = serializers.UUIDField()


class FavoriteSerializer(serializers.ModelSerializer):
    artwork_title = serializers.CharField(source="artwork.title", read_only=True)

    class Meta:
        model = Favorite
        fields = ("id", "artwork", "artwork_title", "created_at")
        read_only_fields = ("id", "created_at", "artwork_title")


class FavoriteToggleSerializer(serializers.Serializer):
    artwork_id = serializers.UUIDField()


class OrderItemSerializer(serializers.ModelSerializer):
    artwork_title = serializers.CharField(source="artwork.title", read_only=True)

    class Meta:
        model = OrderItem
        fields = ("id", "artwork", "artwork_title", "price")
        read_only_fields = ("id", "artwork_title")


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = ("id", "buyer", "total_amount", "status", "order_type", "items", "created_at")
        read_only_fields = ("id", "buyer", "total_amount", "status", "order_type", "items", "created_at")


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

