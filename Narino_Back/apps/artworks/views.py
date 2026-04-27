from django.db import transaction
from django.db.models import F
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.artists.models import ArtistProfile
from apps.artworks.models import Artwork, Category
from apps.artworks.permissions import IsArtworkOwnerOrReadOnly
from apps.artworks.serializers import (
    ArtworkAIEnhanceSerializer,
    ArtworkSerializer,
    CategorySerializer,
)
from services.ai_service import AIService


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]
    lookup_field = "slug"


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
        if not user.is_authenticated:
            return qs.filter(status__in=[Artwork.Status.DISPONIBLE, Artwork.Status.EN_SUBASTA, Artwork.Status.VENDIDA])
        if getattr(user, "role", None) == "ARTISTA":
            profile = ArtistProfile.objects.filter(user=user).first()
            if profile:
                return qs.filter(artist=profile) | qs.filter(status__in=[Artwork.Status.DISPONIBLE, Artwork.Status.EN_SUBASTA, Artwork.Status.VENDIDA])
        return qs.filter(status__in=[Artwork.Status.DISPONIBLE, Artwork.Status.EN_SUBASTA, Artwork.Status.VENDIDA])

    @transaction.atomic
    def perform_create(self, serializer):
        profile = ArtistProfile.objects.filter(user=self.request.user).first()
        if not profile:
            raise ValidationError({"detail": "Perfil de artista no encontrado."})
        serializer.save(artist=profile)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        Artwork.objects.filter(id=instance.id).update(views_count=F("views_count") + 1)
        instance.refresh_from_db()
        return super().retrieve(request, *args, **kwargs)

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

