from rest_framework import serializers

from apps.events.models import Event, EventRegistration


class UserBasicSerializer(serializers.Serializer):
    """Serializer básico para usuario con información mínima"""
    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


class EventSerializer(serializers.ModelSerializer):
    organizer = UserBasicSerializer(read_only=True)

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
            "is_published",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "organizer", "created_at", "updated_at")

    def validate(self, attrs):
        start = attrs.get("start_date") or getattr(self.instance, "start_date", None)
        end = attrs.get("end_date") or getattr(self.instance, "end_date", None)
        if start and end and end < start:
            raise serializers.ValidationError("La fecha fin no puede ser anterior a la fecha inicio.")
        return attrs


class EventRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventRegistration
        fields = ("id", "event", "user", "created_at")
        read_only_fields = fields

