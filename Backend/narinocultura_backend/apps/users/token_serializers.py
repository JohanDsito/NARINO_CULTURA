"""
Custom JWT serializers y tokens para incluir claims personalizados como role.
"""
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer, TokenRefreshSerializer
from rest_framework_simplejwt.settings import api_settings
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
    Renovación con rotación real: devuelve access + refresh nuevo y deja el refresh usado
    en la lista negra. Rechaza la renovación si el usuario fue suspendido o eliminado, y si
    dos peticiones usan a la vez el mismo refresh solo la primera lo consigue rotar.
    """

    def validate(self, attrs):
        refresh = self.token_class(attrs["refresh"])  # TokenError: inválido, expirado o en lista negra
        user_id = refresh.get(api_settings.USER_ID_CLAIM)
        if not User.objects.filter(pk=user_id, is_active=True).exists():
            raise TokenError("Usuario inactivo.")

        # simplejwt 5.3.1 ignora si el token ya estaba en la lista negra al rotarlo: entre
        # check_blacklist() y blacklist() otra petición con el mismo refresh podría colarse.
        # get_or_create sobre la restricción única deja created=False a la que llega segunda.
        _, created = refresh.blacklist()
        if not created:
            raise TokenError("Refresh ya usado.")

        data = {"access": str(refresh.access_token)}
        refresh.set_jti()
        refresh.set_exp()
        refresh.set_iat()
        data["refresh"] = str(refresh)
        return data
