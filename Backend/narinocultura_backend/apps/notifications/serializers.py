from rest_framework import serializers

from apps.notifications.models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    type = serializers.CharField(source="notification_type", read_only=True)
    read = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ("id", "type", "title", "body", "data", "read", "read_at", "created_at")
        read_only_fields = fields

    def get_read(self, obj) -> bool:
        return obj.read_at is not None
