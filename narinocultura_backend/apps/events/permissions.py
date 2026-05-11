from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsEventManagerOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.role in {"GESTOR_CULTURAL", "ADMINISTRADOR"}

