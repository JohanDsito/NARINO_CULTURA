from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.events.models import Event, EventRegistration
from apps.events.permissions import IsEventManagerOrReadOnly
from apps.events.serializers import EventSerializer
from services.notification_service import NotificationService


class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [IsEventManagerOrReadOnly]
    filterset_fields = ("event_type", "is_published")
    search_fields = ("title", "description", "location")
    ordering_fields = ("start_date", "created_at")

    def get_permissions(self):
        if self.action in {"list", "retrieve"}:
            return [AllowAny()]
        return super().get_permissions()

    def get_queryset(self):
        qs = Event.objects.select_related("organizer")
        if self.request.user.is_authenticated and self.request.user.role in {"GESTOR_CULTURAL", "ADMINISTRADOR"}:
            return qs
        return qs.filter(is_published=True)

    def perform_create(self, serializer):
        serializer.save(organizer=self.request.user)

    def perform_update(self, serializer):
        was_published = bool(self.get_object().is_published)
        event = serializer.save()
        if event.is_published and not was_published:
            NotificationService.send(
                "EVENT_PUBLISHED",
                {"event_id": str(event.id), "title": event.title, "start_date": event.start_date.isoformat()},
                user=self.request.user,
            )

    @action(detail=True, methods=["post"], url_path="register")
    @transaction.atomic
    def register(self, request, pk=None):
        event = self.get_object()
        if not request.user.is_authenticated:
            return Response({"detail": "Autenticación requerida."}, status=401)
        reg, created = EventRegistration.objects.get_or_create(event=event, user=request.user)
        if not created:
            return Response({"detail": "Ya estás inscrito en este evento."}, status=400)
        NotificationService.send(
            "EVENT_REGISTRATION",
            {"event_id": str(event.id), "user_id": str(request.user.id)},
            user=request.user,
        )
        return Response({"detail": "Inscripción realizada."}, status=status.HTTP_201_CREATED)

