from django.utils import timezone
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.models import Notification
from apps.notifications.serializers import NotificationSerializer

TRUTHY = {"1", "true", "si", "sí", "yes"}


class NotificationListAPIView(generics.ListAPIView):
    """Bandeja del usuario autenticado. `?unread=true` (o `?no_leidas=true`) solo trae las no leídas."""

    serializer_class = NotificationSerializer

    def get_queryset(self):
        qs = Notification.objects.filter(recipient=self.request.user)
        params = self.request.query_params
        if (params.get("unread") or params.get("no_leidas") or "").lower() in TRUTHY:
            qs = qs.filter(read_at__isnull=True)
        return qs


class NotificationUnreadCountAPIView(APIView):
    def get(self, request):
        count = Notification.objects.filter(recipient=request.user, read_at__isnull=True).count()
        return Response({"unread": count})


class NotificationMarkReadAPIView(APIView):
    def post(self, request, pk):
        notification = Notification.objects.filter(id=pk, recipient=request.user).first()
        if not notification:
            return Response({"detail": "Notificación no encontrada."}, status=status.HTTP_404_NOT_FOUND)
        if notification.read_at is None:
            notification.read_at = timezone.now()
            notification.save(update_fields=["read_at", "updated_at"])
        return Response(NotificationSerializer(notification).data)

    # La app móvil marca como leída con PATCH
    patch = post


class NotificationMarkAllReadAPIView(APIView):
    def post(self, request):
        updated = Notification.objects.filter(recipient=request.user, read_at__isnull=True).update(
            read_at=timezone.now(), updated_at=timezone.now()
        )
        return Response({"updated": updated})
