from rest_framework.permissions import SAFE_METHODS, BasePermission


class IsAuctionSellerOrAdmin(BasePermission):
    message = "Solo el vendedor de la subasta o un administrador pueden modificarla."

    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        user = request.user
        return obj.seller_id == user.id or getattr(user, "role", None) == "ADMINISTRADOR"
