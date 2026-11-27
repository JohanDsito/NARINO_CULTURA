import logging
import secrets
from datetime import timedelta

from django.db import transaction
from django.db.models import ProtectedError, Q, Sum
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.administration.serializers import AdminCreateUserSerializer, AdminUserSerializer, ArtworkModerationSerializer
from apps.artworks.models import Artwork
from apps.auctions.models import Auction
from apps.events.models import Event
from apps.marketplace.models import Order
from apps.notifications.models import NotificationLog
from apps.payments.models import Transaction
from apps.users.models import User
from services.email_service import EmailService
from utils.permissions import IsAdmin

logger = logging.getLogger(__name__)


class AdminCreateUserAPIView(APIView):
    """List all users (GET) or create a user with any role (POST). Admin only."""

    permission_classes = [IsAdmin]

    def get(self, request):
        """Lista de usuarios con búsqueda (`?search=` en correo y nombre) y filtros `?role=`, `?is_active=` y
        `?is_verified=` (true/false). Sigue siendo una lista sin paginar: la web la consume así."""
        users = User.objects.all().order_by("-created_at")
        params = request.query_params
        term = params.get("search", "").strip()
        if term:
            users = users.filter(Q(email__icontains=term) | Q(first_name__icontains=term) | Q(last_name__icontains=term))
        if params.get("role"):
            users = users.filter(role=params["role"].upper())
        for flag in ("is_active", "is_verified"):
            value = params.get(flag, "").lower()
            if value in {"true", "false"}:
                users = users.filter(**{flag: value == "true"})
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


class AdminSafetyError(APIException):
    """400 con `detail` legible y `code` estable para las reglas de autoprotección del admin."""

    status_code = status.HTTP_400_BAD_REQUEST

    def __init__(self, detail, code):
        super().__init__({"detail": detail, "code": code})


class AdminUserDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdmin]
    queryset = User.objects.all()

    @staticmethod
    def _lock_active_admins():
        """Bloquea las filas de administradores activos y devuelve sus ids (evita carreras)."""
        return set(
            User.objects.select_for_update()
            .filter(role=User.Role.ADMINISTRADOR, is_active=True)
            .values_list("pk", flat=True)
        )

    def _check_safety(self, target, new_role, new_active, deleting=False):
        """Impide que un admin se degrade, suspenda o elimine, y que no quede ningún admin activo."""
        is_self = target.pk == self.request.user.pk
        if is_self and deleting:
            raise AdminSafetyError("No puedes eliminar tu propia cuenta.", "admin_self_change")
        if is_self and (new_role != User.Role.ADMINISTRADOR or not new_active):
            raise AdminSafetyError(
                "No puedes quitarte el rol de administrador ni suspender tu propia cuenta.", "admin_self_change"
            )
        admins = self._lock_active_admins()
        stays_admin = not deleting and new_role == User.Role.ADMINISTRADOR and new_active
        if target.pk in admins and not stays_admin and len(admins) <= 1:
            raise AdminSafetyError("Debe quedar al menos un administrador activo.", "last_admin")

    def perform_update(self, serializer):
        with transaction.atomic():
            target = User.objects.select_for_update().get(pk=serializer.instance.pk)
            data = serializer.validated_data
            self._check_safety(target, data.get("role", target.role), data.get("is_active", target.is_active))
            serializer.save()

    def perform_destroy(self, instance):
        with transaction.atomic():
            target = User.objects.select_for_update().get(pk=instance.pk)
            self._check_safety(target, target.role, target.is_active, deleting=True)
            target.delete()

    def destroy(self, request, *args, **kwargs):
        try:
            return super().destroy(request, *args, **kwargs)
        except ProtectedError:
            return Response(
                {
                    "detail": (
                        "No se puede eliminar este usuario porque tiene obras vendidas. "
                        "Suspéndelo (is_active = false) en su lugar."
                    ),
                    "code": "user_has_sales",
                },
                status=status.HTTP_409_CONFLICT,
            )


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

    post = patch

    def delete(self, request, pk=None):
        artwork = Artwork.objects.filter(id=pk).first()
        if not artwork:
            return Response({"detail": "Obra no encontrada."}, status=404)
        try:
            artwork.delete()
        except ProtectedError:
            # Mismo criterio que ArtworkViewSet.admin_delete: una obra con órdenes no se borra
            return Response(
                {"detail": "No se puede eliminar esta obra porque tiene órdenes de compra asociadas. Márcala como INACTIVA en su lugar."},
                status=status.HTTP_409_CONFLICT,
            )
        return Response(status=204)


class AdminTransactionsAPIView(generics.ListAPIView):
    serializer_class = None
    permission_classes = [IsAdmin]

    def list(self, request, *args, **kwargs):
        qs = Transaction.objects.select_related("order", "order__buyer").order_by("-created_at")
        data = [
            {
                "id": str(t.id),
                "order_id": str(t.order_id),
                "buyer_email": t.order.buyer_email,
                "amount": str(t.amount),
                "currency": t.currency,
                "status": t.status,
                "total_amount": str(t.order.total_amount),
                "order_type": t.order.order_type,
                "order_status": t.order.status,
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
        since = timezone.now() - timedelta(days=30)
        users_total = User.objects.count()
        artworks_total = Artwork.objects.count()
        transactions_total = Transaction.objects.count()
        revenue_last_30_days = (
            Transaction.objects.filter(status=Transaction.Status.APROBADO, created_at__gte=since)
            .aggregate(total=Sum("amount"))["total"]
            or 0
        )
        return Response(
            {
                # Campos que consume el dashboard del frontend
                "total_users": users_total,
                "total_artworks": artworks_total,
                "total_transactions": transactions_total,
                "new_users_last_30_days": User.objects.filter(created_at__gte=since).count(),
                "revenue_last_30_days": str(revenue_last_30_days),
                # Campos originales (se mantienen por compatibilidad con Postman/clientes existentes)
                "users": users_total,
                "artists": User.objects.filter(role=User.Role.ARTISTA).count(),
                "artworks_total": artworks_total,
                "artworks_pending": Artwork.objects.filter(status=Artwork.Status.INACTIVA).count(),
                "orders_total": Order.objects.count(),
                "transactions_total": transactions_total,
                "auctions_active": Auction.objects.filter(status=Auction.Status.ACTIVA).count(),
                "events_total": Event.objects.count(),
                "events_published": Event.objects.filter(is_published=True).count(),
            }
        )

