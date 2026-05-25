"""
Custom JWT serializers y tokens para incluir claims personalizados como role.
"""
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken


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
