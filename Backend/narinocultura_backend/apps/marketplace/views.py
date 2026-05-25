from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.marketplace.models import Favorite, Order
from apps.marketplace.serializers import (
    CartItemAddSerializer,
    CartSerializer,
    CheckoutSerializer,
    FavoriteToggleSerializer,
    OrderSerializer,
)
from services.marketplace_service import MarketplaceService


class CartAPIView(APIView):
    def get(self, request):
        cart = MarketplaceService.get_or_create_cart(user=request.user)
        serializer = CartSerializer(cart)
        return Response(serializer.data)


class CartItemsAPIView(APIView):
    def post(self, request):
        serializer = CartItemAddSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            MarketplaceService.add_to_cart(user=request.user, artwork_id=serializer.validated_data["artwork_id"])
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"detail": "Obra agregada al carrito."}, status=status.HTTP_201_CREATED)

    def delete(self, request):
        serializer = CartItemAddSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            MarketplaceService.remove_from_cart(user=request.user, artwork_id=serializer.validated_data["artwork_id"])
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"detail": "Obra eliminada del carrito."})


class FavoritesAPIView(APIView):
    def get(self, request):
        qs = Favorite.objects.select_related("artwork").filter(user=request.user)
        data = [{"id": str(f.id), "artwork_id": str(f.artwork_id), "title": f.artwork.title, "created_at": f.created_at} for f in qs]
        return Response(data)

    def post(self, request):
        serializer = FavoriteToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        artwork_id = serializer.validated_data["artwork_id"]
        fav, created = Favorite.objects.get_or_create(user=request.user, artwork_id=artwork_id)
        if not created:
            return Response({"detail": "Ya está en favoritos."}, status=400)
        return Response({"detail": "Agregado a favoritos."}, status=status.HTTP_201_CREATED)

    def delete(self, request):
        serializer = FavoriteToggleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        deleted, _ = Favorite.objects.filter(user=request.user, artwork_id=serializer.validated_data["artwork_id"]).delete()
        if not deleted:
            return Response({"detail": "No está en favoritos."}, status=400)
        return Response({"detail": "Eliminado de favoritos."})


class CheckoutAPIView(APIView):
    def post(self, request):
        serializer = CheckoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            order = MarketplaceService.checkout(user=request.user, order_type=serializer.validated_data["order_type"])
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"order_id": str(order.id), "total_amount": str(order.total_amount)}, status=status.HTTP_201_CREATED)


class OrdersAPIView(generics.ListAPIView):
    serializer_class = OrderSerializer

    def get_queryset(self):
        return Order.objects.select_related("buyer").prefetch_related("items", "items__artwork").filter(buyer=self.request.user)


class SalesAPIView(generics.ListAPIView):
    serializer_class = OrderSerializer

    def get_queryset(self):
        return (
            Order.objects.select_related("buyer")
            .prefetch_related("items", "items__artwork", "items__artwork__artist", "items__artwork__artist__user")
            .filter(items__artwork__artist__user=self.request.user, status=Order.Status.PAGADO)
            .distinct()
        )

