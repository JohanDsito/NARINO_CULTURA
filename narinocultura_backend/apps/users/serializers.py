import logging
from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
import jwt
from django.conf import settings

from apps.users.models import EmailVerification, PasswordReset, User

logger = logging.getLogger(__name__)


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ("email", "password", "first_name", "last_name", "role", "phone")

    def validate_role(self, value):
        roles = {c for c, _ in User.Role.choices}
        if value not in roles:
            raise serializers.ValidationError("Rol inválido.")
        self_registerable = {User.Role.ARTISTA, User.Role.COMPRADOR}
        if value not in self_registerable:
            raise serializers.ValidationError("Este rol solo puede ser asignado por un administrador.")
        return value

    def create(self, validated_data):
        password = validated_data.pop("password")
        return User.objects.create_user(password=password, **validated_data)


class EmailVerificationSerializer(serializers.Serializer):
    token = serializers.CharField()


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(
            request=self.context.get("request"),
            email=attrs.get("email"),
            password=attrs.get("password"),
        )
        if not user:
            raise serializers.ValidationError("Credenciales inválidas.")
        if not user.is_active:
            raise serializers.ValidationError("Usuario inactivo.")
        if not user.is_verified:
            raise serializers.ValidationError("Debe verificar su email antes de iniciar sesión.")
        refresh = RefreshToken.for_user(user)
        refresh['role'] = user.role
        logger.info(f"LoginSerializer: Added role {user.role} to refresh token")
        logger.info(f"LoginSerializer: Refresh payload has role: {'role' in refresh.payload}")
        access_token = refresh.access_token
        logger.info(f"LoginSerializer: Access payload has role: {'role' in access_token.payload}")
        return {"user": user, "refresh": str(refresh), "access": str(access_token)}


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(write_only=True, min_length=8)


class UserMeSerializer(serializers.ModelSerializer):
    avatar_url = serializers.SerializerMethodField(read_only=True)
    avatar = serializers.ImageField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = User
        fields = ("id", "email", "first_name", "last_name", "role", "phone", "avatar_url", "avatar", "is_verified")
        read_only_fields = ("id", "email", "role", "is_verified")

    def get_avatar_url(self, obj):
        if not obj.avatar:
            return ""
        request = self.context.get("request")
        return request.build_absolute_uri(obj.avatar.url) if request else obj.avatar.url


class PasswordChangeSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=8)

