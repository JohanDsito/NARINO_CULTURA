"""
Custom JWT serializers y tokens para incluir claims personalizados como role.
"""
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer, TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Serializer personalizado que agrega el claim 'role' al JWT.
    """

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        return token


class CustomRefreshToken(RefreshToken):
    """Refresh token con claim 'role' incluido."""

    @classmethod
    def for_user(cls, user):
        token = super().for_user(user)
        token['role'] = user.role
        return token


class ActiveUserTokenRefreshSerializer(TokenRefreshSerializer):
    """
    Renovación con rotación real (ROTATE_REFRESH_TOKENS / BLACKLIST_AFTER_ROTATION):
    devuelve access + refresh nuevo y deja el refresh usado en la lista negra.
    Rechaza la renovación si el usuario fue suspendido o eliminado.
    """

    def validate(self, attrs):
        token = RefreshToken(attrs["refresh"])  # TokenError si es inválido, expirado o está en lista negra
        if not User.objects.filter(pk=token.get("user_id"), is_active=True).exists():
            raise TokenError("Usuario inactivo.")
        return super().validate(attrs)
