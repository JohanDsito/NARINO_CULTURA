import logging
import secrets

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
from apps.administration.serializers import AdminCreateUserSerializer, AdminUserSerializer, ArtworkModerationSerializer
from services.email_service import EmailService
from utils.permissions import IsAdmin

logger = logging.getLogger(__name__)


class AdminCreateUserAPIView(APIView):
    """List all users (GET) or create a user with any role (POST). Admin only."""

    permission_classes = [IsAdmin]

    def get(self, request):
        users = User.objects.all().order_by("-date_joined")
        serializer = AdminUserSerializer(users, many=True, context={"request": request})
        return Response(serializer.data)

    def post(self, request):
        serializer = AdminCreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        temp_password = secrets.token_urlsafe(12)
        user = User.objects.create_user(
            email=data["email"],
            password=temp_password,
            first_name=data["first_name"],
            last_name=data["last_name"],
            role=data["role"],
            phone=data.get("phone", ""),
            is_verified=True,
        )

        full_name = f"{user.first_name} {user.last_name}".strip() or user.email
        result = EmailService.send_admin_created_account_email(
            user_email=user.email,
            user_name=full_name,
            temp_password=temp_password,
            role_display=user.get_role_display(),
        )
        if not result.ok:
            logger.warning(f"No se pudo enviar email de credenciales a {user.email}: {result.error_message}")

        return Response(
            {
                "id": str(user.id),
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "role": user.role,
                "is_verified": user.is_verified,
            },
            status=status.HTTP_201_CREATED,
        )


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

