from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsArtworkOwnerOrReadOnly(BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        user = getattr(request, "user", None)
        return bool(user and user.is_authenticated and obj.artist.user_id == user.id)

