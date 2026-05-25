from rest_framework.permissions import BasePermission


class HasRole(BasePermission):
    allowed_roles = ()

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.role in self.allowed_roles


class IsArtist(HasRole):
    allowed_roles = ("ARTISTA",)


class IsBuyer(HasRole):
    allowed_roles = ("COMPRADOR",)


class IsCulturalManager(HasRole):
    allowed_roles = ("GESTOR_CULTURAL", "ADMINISTRADOR")


class IsAdmin(HasRole):
    allowed_roles = ("ADMINISTRADOR",)

