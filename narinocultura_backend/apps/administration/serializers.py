from rest_framework import serializers

from apps.artworks.models import Artwork
from apps.users.models import User


class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email", "first_name", "last_name", "role", "is_active", "is_verified", "phone", "avatar_url")
        read_only_fields = ("id", "email")


class ArtworkModerationSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Artwork.Status.choices)
    reason = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if value not in {Artwork.Status.DISPONIBLE, Artwork.Status.INACTIVA}:
            raise serializers.ValidationError("El estado permitido para moderación es DISPONIBLE o INACTIVA.")
        return value

