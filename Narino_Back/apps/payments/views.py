from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.payments.models import Transaction
from apps.payments.serializers import PaymentInitiateSerializer, TransactionSerializer
from services.payment_service import PaymentService


class InitiatePaymentAPIView(APIView):
    def post(self, request):
        serializer = PaymentInitiateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            data = PaymentService.initiate_payment(user=request.user, order_id=serializer.validated_data["order_id"])
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response(data, status=status.HTTP_201_CREATED)


class WompiWebhookAPIView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        try:
            PaymentService.process_wompi_webhook(payload=request.data)
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"detail": "OK"})


class TransactionListAPIView(generics.ListAPIView):
    serializer_class = TransactionSerializer

    def get_queryset(self):
        user = self.request.user
        if getattr(user, "role", None) == "ADMINISTRADOR":
            return Transaction.objects.select_related("order", "order__buyer")
        return Transaction.objects.select_related("order", "order__buyer").filter(order__buyer=user)


class TransactionReceiptAPIView(APIView):
    def get(self, request, pk=None):
        tx = Transaction.objects.select_related("order", "order__buyer").filter(id=pk).first()
        if not tx:
            return Response({"detail": "Transacción no encontrada."}, status=404)
        if getattr(request.user, "role", None) != "ADMINISTRADOR" and tx.order.buyer_id != request.user.id:
            return Response({"detail": "No tienes permisos para ver este comprobante."}, status=403)
        if not tx.receipt_url:
            return Response({"detail": "Comprobante no disponible."}, status=404)
        return Response({"receipt_url": tx.receipt_url})

