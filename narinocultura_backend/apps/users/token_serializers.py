"""
Custom JWT serializers para incluir claims personalizados como role.
"""
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Serializer personalizado que agrega el claim 'role' al JWT.
    """

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Agregar claim personalizado: role
        token["role"] = user.role

        return token
