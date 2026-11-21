from rest_framework import serializers

from apps.events.models import Event, EventRegistration
from services import llm
from services.event_service import EventService
from utils.media import sniff_image_type

FLYER_MAX_BYTES = 5 * 1024 * 1024


def read_flyer_upload(upload) -> llm.Image:
    """Valida el afiche subido (JPEG, PNG, WebP o HEIC de hasta 5 MB) y lo devuelve leído."""
    if upload.size > FLYER_MAX_BYTES:
        raise serializers.ValidationError("El afiche no puede pesar más de 5 MB.")
    data = upload.read()
    mime_type = sniff_image_type(data)
    if mime_type is None:
        raise serializers.ValidationError("El afiche debe ser una imagen JPEG, PNG, WebP o HEIC.")
    return llm.Image(mime_type=mime_type, data=data)


class UserBasicSerializer(serializers.Serializer):
    """Datos públicos del organizador. Sin correo: la agenda es pública (Ley 1581 de 2012)."""
    id = serializers.UUIDField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


class EventSerializer(serializers.ModelSerializer):
    organizer = UserBasicSerializer(read_only=True)
    is_registered = serializers.SerializerMethodField()
    # Archivo opcional (multipart): se guarda y su URL queda en image_url
    flyer = serializers.FileField(write_only=True, required=False)

    class Meta:
        model = Event
        fields = (
            "id",
            "organizer",
            "title",
            "description",
            "event_type",
            "start_date",
            "end_date",
            "location",
            "latitude",
            "longitude",
            "image_url",
            "flyer",
            "is_published",
            "is_registered",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "organizer", "created_at", "updated_at")

    def validate_flyer(self, upload):
        return read_flyer_upload(upload)

    def update(self, instance, validated_data):
        flyer = validated_data.pop("flyer", None)
        if flyer is not None:
            validated_data["image_url"] = EventService.store_flyer(flyer)
        return super().update(instance, validated_data)

    def get_is_registered(self, obj) -> bool:
        # Anotado en EventViewSet.get_queryset; si el evento no viene anotado se consulta aquí
        if hasattr(obj, "user_registered"):
            return bool(obj.user_registered)
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False
        return EventRegistration.objects.filter(event=obj, user=request.user).exists()

    def validate(self, attrs):
        request = self.context.get("request")
        start = attrs.get("start_date") or getattr(self.instance, "start_date", None)
        end = attrs.get("end_date") or getattr(self.instance, "end_date", None)
        if start and end and end < start:
            raise serializers.ValidationError("La fecha fin no puede ser anterior a la fecha inicio.")

        if request and getattr(request.user, "role", None) == "ARTISTA":
            desired_published = attrs.get("is_published", getattr(self.instance, "is_published", False))
            if desired_published:
                raise serializers.ValidationError(
                    {"is_published": "Los artistas no pueden publicar eventos directamente."}
                )
        return attrs


class EventRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventRegistration
        fields = ("id", "event", "user", "created_at")
        read_only_fields = fields


class EventFlyerExtractSerializer(serializers.Serializer):
    image_url = serializers.URLField(required=False, allow_blank=True)
    flyer = serializers.FileField(required=False)
    flyer_text = serializers.CharField(required=False, allow_blank=True)
    create_draft = serializers.BooleanField(default=False)

    def validate_flyer(self, upload):
        return read_flyer_upload(upload)

    def validate(self, attrs):
        image_url = attrs.get("image_url", "").strip()
        flyer_text = attrs.get("flyer_text", "").strip()

        if not image_url and not flyer_text and not attrs.get("flyer"):
            raise serializers.ValidationError(
                "Debes enviar el afiche (archivo o URL) o el texto del afiche."
            )
        return attrs


class EventFlyerExtractionResultSerializer(serializers.Serializer):
    title = serializers.CharField(allow_blank=True)
    description = serializers.CharField(allow_blank=True)
    event_type = serializers.CharField(allow_blank=True)
    start_date = serializers.DateTimeField(allow_null=True)
    end_date = serializers.DateTimeField(allow_null=True)
    location = serializers.CharField(allow_blank=True)
    image_url = serializers.URLField(allow_blank=True)
    is_published = serializers.BooleanField()
    source = serializers.CharField()
    raw_text = serializers.CharField(allow_blank=True)

