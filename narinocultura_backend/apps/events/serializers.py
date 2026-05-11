from rest_framework import serializers

from apps.events.models import Event, EventRegistration


class EventSerializer(serializers.ModelSerializer):
    organizer_id = serializers.UUIDField(source="organizer.id", read_only=True)

    class Meta:
        model = Event
        fields = (
            "id",
            "organizer_id",
            "title",
            "description",
            "event_type",
            "start_date",
            "end_date",
            "location",
            "latitude",
            "longitude",
            "image_url",
            "is_published",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "organizer_id", "created_at", "updated_at")

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
    flyer_text = serializers.CharField(required=False, allow_blank=True)
    create_draft = serializers.BooleanField(default=False)

    def validate(self, attrs):
        image_url = attrs.get("image_url", "").strip()
        flyer_text = attrs.get("flyer_text", "").strip()

        if not image_url and not flyer_text:
            raise serializers.ValidationError(
                "Debes enviar al menos una URL del flyer o texto extraido del flyer."
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

