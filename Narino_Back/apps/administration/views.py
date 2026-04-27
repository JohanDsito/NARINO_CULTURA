from django.db.models import Count
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.auctions.models import Auction
from apps.artworks.models import Artwork
from apps.events.models import Event
from apps.marketplace.models import Order
from apps.notifications.models import NotificationLog
from apps.payments.models import Transaction
from apps.users.models import User
from apps.administration.serializers import AdminUserSerializer, ArtworkModerationSerializer
from utils.permissions import IsAdmin


class AdminUserDetailAPIView(generics.RetrieveUpdateAPIView):
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdmin]
    queryset = User.objects.all()


class PendingArtworksAPIView(generics.ListAPIView):
    permission_classes = [IsAdmin]

    def get_queryset(self):
        return Artwork.objects.select_related("artist", "artist__user", "category").filter(status=Artwork.Status.INACTIVA)

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()
        data = [
            {
                "id": str(a.id),
                "title": a.title,
                "artist_slug": a.artist.slug,
                "price": str(a.price),
                "created_at": a.created_at,
            }
            for a in qs
        ]
        return Response(data)


class ModerateArtworkAPIView(APIView):
    permission_classes = [IsAdmin]

    def patch(self, request, pk=None):
        artwork = Artwork.objects.select_related("artist", "artist__user").filter(id=pk).first()
        if not artwork:
            return Response({"detail": "Obra no encontrada."}, status=404)
        serializer = ArtworkModerationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        artwork.status = serializer.validated_data["status"]
        artwork.save(update_fields=["status", "updated_at"])
        return Response({"detail": "Obra moderada correctamente."})


class AdminTransactionsAPIView(generics.ListAPIView):
    serializer_class = None
    permission_classes = [IsAdmin]

    def list(self, request, *args, **kwargs):
        qs = Transaction.objects.select_related("order", "order__buyer").order_by("-created_at")
        data = [
            {
                "id": str(t.id),
                "order_id": str(t.order_id),
                "buyer_email": t.order.buyer.email,
                "amount": str(t.amount),
                "currency": t.currency,
                "status": t.status,
                "created_at": t.created_at,
            }
            for t in qs
        ]
        return Response(data)


class AdminNotificationLogAPIView(generics.ListAPIView):
    permission_classes = [IsAdmin]

    def list(self, request, *args, **kwargs):
        qs = NotificationLog.objects.select_related("user").order_by("-sent_at")
        data = [
            {
                "id": str(n.id),
                "notification_type": n.notification_type,
                "status": n.status,
                "user_email": n.user.email if n.user_id else None,
                "sent_at": n.sent_at,
            }
            for n in qs
        ]
        return Response(data)


class AdminMetricsAPIView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        return Response(
            {
                "users": User.objects.count(),
                "artists": User.objects.filter(role=User.Role.ARTISTA).count(),
                "artworks_total": Artwork.objects.count(),
                "artworks_pending": Artwork.objects.filter(status=Artwork.Status.INACTIVA).count(),
                "orders_total": Order.objects.count(),
                "transactions_total": Transaction.objects.count(),
                "auctions_active": Auction.objects.filter(status=Auction.Status.ACTIVA).count(),
                "events_total": Event.objects.count(),
                "events_published": Event.objects.filter(is_published=True).count(),
            }
        )

