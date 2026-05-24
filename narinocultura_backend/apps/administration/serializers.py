from rest_framework import serializers

from apps.artworks.models import Artwork
from apps.users.models import User


class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email", "first_name", "last_name", "role", "is_active", "is_verified", "phone", "avatar_url")
        read_only_fields = ("id", "email")


class AdminCreateUserSerializer(serializers.Serializer):
    email = serializers.EmailField()
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    role = serializers.ChoiceField(choices=User.Role.choices)
    phone = serializers.CharField(max_length=30, required=False, allow_blank=True, default="")

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Ya existe un usuario con este correo.")
        return value


class ArtworkModerationSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Artwork.Status.choices)
    reason = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        if value not in {Artwork.Status.DISPONIBLE, Artwork.Status.INACTIVA}:
            raise serializers.ValidationError("El estado permitido para moderación es DISPONIBLE o INACTIVA.")
        return value

