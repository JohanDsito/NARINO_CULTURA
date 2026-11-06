from rest_framework import serializers

from apps.auctions.models import Auction, Bid


class AuctionSerializer(serializers.ModelSerializer):
    artwork_id = serializers.UUIDField(source="artwork.id", read_only=True)
    payment_order_id = serializers.SerializerMethodField()

    class Meta:
        model = Auction
        fields = (
            "id",
            "artwork",
            "artwork_id",
            "seller",
            "base_price",
            "current_price",
            "highest_bidder",
            "status",
            "starts_at",
            "ends_at",
            "winner",
            "payment_order_id",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "seller", "current_price", "highest_bidder", "status", "winner", "created_at", "updated_at")

    def get_payment_order_id(self, obj):
        # Solo el ganador ve la orden que debe pagar
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if obj.payment_order_id and user and user.is_authenticated and user.id == obj.winner_id:
            return str(obj.payment_order_id)
        return None

    def validate(self, attrs):
        # En una edición parcial, las fechas que no se envían se toman de la subasta guardada
        starts_at = attrs.get("starts_at", getattr(self.instance, "starts_at", None))
        ends_at = attrs.get("ends_at", getattr(self.instance, "ends_at", None))
        base_price = attrs.get("base_price")
        if starts_at and ends_at and ends_at <= starts_at:
            raise serializers.ValidationError("La fecha fin debe ser mayor que la fecha inicio.")
        if base_price is not None and base_price <= 0:
            raise serializers.ValidationError("El precio base debe ser mayor que 0.")
        return attrs


class BidCreateSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class BidSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bid
        fields = ("id", "auction", "bidder", "amount", "created_at")
        read_only_fields = fields

