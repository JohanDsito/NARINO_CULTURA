from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.events.models import Event, EventRegistration
from apps.events.permissions import IsEventManagerOrReadOnly
from apps.events.serializers import (
    EventFlyerExtractSerializer,
    EventFlyerExtractionResultSerializer,
    EventSerializer,
)
from services.event_service import EventService
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
        if self.request.user.is_authenticated and self.request.user.role == "ARTISTA":
            return qs.filter(is_published=True) | qs.filter(organizer=self.request.user)
        return qs.filter(is_published=True)

    def perform_create(self, serializer):
        serializer.instance = EventService.create_event(
            organizer=self.request.user,
            validated_data=dict(serializer.validated_data),
        )

    def perform_update(self, serializer):
        was_published = bool(self.get_object().is_published)
        event = serializer.save()
        if event.is_published and not was_published:
            NotificationService.send(
                "EVENT_PUBLISHED",
                {"event_id": str(event.id), "title": event.title, "start_date": event.start_date.isoformat()},
                user=self.request.user,
            )

    @action(detail=False, methods=["post"], url_path="extract-from-flyer")
    def extract_from_flyer(self, request):
        serializer = EventFlyerExtractSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        extracted = EventService.extract_from_flyer(
            organizer=request.user,
            image_url=serializer.validated_data.get("image_url", ""),
            flyer_text=serializer.validated_data.get("flyer_text", ""),
        )

        response_data = {
            "suggested_event": EventFlyerExtractionResultSerializer(extracted).data,
            "draft_created": False,
            "event": None,
        }

        if serializer.validated_data["create_draft"]:
            try:
                event = EventService.create_draft_from_extraction(
                    organizer=request.user,
                    extracted_data=extracted,
                )
            except ValueError as e:
                return Response(
                    {
                        "detail": str(e),
                        "suggested_event": EventFlyerExtractionResultSerializer(extracted).data,
                        "draft_created": False,
                        "event": None,
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )
            response_data["draft_created"] = True
            response_data["event"] = EventSerializer(event, context={"request": request}).data

        return Response(response_data, status=status.HTTP_200_OK)

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

