from rest_framework import serializers

from apps.payments.models import Transaction


class PaymentInitiateSerializer(serializers.Serializer):
    order_id = serializers.UUIDField()


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = (
            "id",
            "order",
            "wompi_transaction_id",
            "amount",
            "currency",
            "status",
            "payment_method",
            "receipt_url",
            "created_at",
        )
        read_only_fields = fields

