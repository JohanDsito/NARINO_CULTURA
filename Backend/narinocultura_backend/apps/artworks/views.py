from django.core.cache import cache
from django.db import transaction
from django.db.models import F
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from django.db.models import ProtectedError

from apps.artists.models import ArtistProfile
from apps.artworks.models import Artwork, Category
from apps.artworks.permissions import IsArtworkOwnerOrReadOnly
from apps.artworks.serializers import (
    ArtworkAIEnhanceSerializer,
    ArtworkSerializer,
    CategorySerializer,
)
from services.ai_service import AIService
from utils.permissions import IsAdmin


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]
    lookup_field = "slug"

    @method_decorator(cache_page(60 * 60))  # 1 hour — categories rarely change
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)


class ArtworkViewSet(viewsets.ModelViewSet):
    serializer_class = ArtworkSerializer
    permission_classes = [IsArtworkOwnerOrReadOnly]
    filterset_fields = ("status", "category")
    search_fields = ("title", "description", "technique", "material")
    ordering_fields = ("created_at", "price", "views_count")

    def get_queryset(self):
        qs = (
            Artwork.objects.select_related("artist", "artist__user", "category")
            .prefetch_related("images")
        )
        user = self.request.user
        artist_slug = self.request.query_params.get("artist")
        public_statuses = [
            Artwork.Status.DISPONIBLE,
            Artwork.Status.EN_SUBASTA,
            Artwork.Status.VENDIDA,
        ]

        if artist_slug:
            qs = qs.filter(artist__slug=artist_slug)
            if user.is_authenticated and ArtistProfile.objects.filter(
                user=user, slug=artist_slug
            ).exists():
                return qs
            return qs.filter(status__in=public_statuses)

        if self.request.query_params.get("mine") == "true" and user.is_authenticated:
            profile = ArtistProfile.objects.filter(user=user).first()
            if profile:
                return qs.filter(artist=profile)
            return qs.none()

        return qs.filter(status__in=public_statuses)

    @transaction.atomic
    def perform_create(self, serializer):
        profile = ArtistProfile.objects.filter(user=self.request.user).first()
        if not profile:
            raise ValidationError({"detail": "Perfil de artista no encontrado."})
        serializer.save(artist=profile)
        cache.delete_pattern("*.artworks*") if hasattr(cache, "delete_pattern") else None

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        Artwork.objects.filter(id=instance.id).update(views_count=F("views_count") + 1)
        instance.refresh_from_db()
        return super().retrieve(request, *args, **kwargs)

    @action(detail=True, methods=["delete"], url_path="delete", permission_classes=[IsAdmin])
    def admin_delete(self, request, pk=None):
        artwork = Artwork.objects.filter(id=pk).first()
        if not artwork:
            return Response({"detail": "Obra no encontrada."}, status=404)
        try:
            artwork.delete()
        except ProtectedError:
            return Response(
                {"detail": "No se puede eliminar esta obra porque tiene órdenes de compra asociadas. Márcala como INACTIVA en su lugar."},
                status=409,
            )
        return Response(status=204)

    @action(detail=True, methods=["post"], url_path="ai-enhance")
    @transaction.atomic
    def ai_enhance(self, request, pk=None):
        artwork = self.get_object()
        serializer = ArtworkAIEnhanceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            result = AIService.enhance_artwork(
                artwork=artwork, regenerate_description=serializer.validated_data["regenerate_description"]
            )
        except RuntimeError as e:
            return Response({"detail": str(e)}, status=400)
        return Response(result, status=status.HTTP_200_OK)

