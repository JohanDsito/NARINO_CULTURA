from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsEventManagerOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.role in {"ARTISTA", "GESTOR_CULTURAL", "ADMINISTRADOR"}

    def has_object_permission(self, request, view, obj):
        user = request.user

        if request.method in SAFE_METHODS:
            if obj.is_published:
                return True
            if not user or not user.is_authenticated:
                return False
            if getattr(user, "role", None) == "ADMINISTRADOR":
                return True
            return obj.organizer_id == user.id

        if not user or not user.is_authenticated:
            return False
        if getattr(user, "role", None) == "ADMINISTRADOR":
            return True
        return obj.organizer_id == user.id

