from django.db import transaction
from django.db.models import F
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.artists.models import ArtistProfile, Follow
from apps.artists.serializers import ArtistProfileSerializer, ArtistProfileSummarySerializer
from apps.users.serializers import PublicUserSummarySerializer


class ArtistProfileViewSet(viewsets.ModelViewSet):
    serializer_class = ArtistProfileSerializer
    lookup_field = "slug"

    def get_permissions(self):
        if self.action in {"list", "retrieve"}:
            return [AllowAny()]
        return super().get_permissions()

    def get_queryset(self):
        qs = ArtistProfile.objects.select_related("user")
        if self.action in {"list", "retrieve"} and not self.request.user.is_authenticated:
            return qs.filter(is_public=True)
        if self.action in {"list", "retrieve"}:
            return qs.filter(is_public=True) | qs.filter(user=self.request.user)
        if self.action == "follow":
            # Se puede seguir cualquier perfil público (no solo el propio)
            return qs.filter(is_public=True)
        # update / partial_update / destroy / followers — solo el perfil propio
        return qs.filter(user=self.request.user)

    @action(detail=True, methods=["get"], url_path="followers")
    def followers(self, request, slug=None):
        """Usuarios que siguen al artista. Solo visible para el dueño del perfil."""
        profile = self.get_object()
        follows = Follow.objects.filter(artist=profile).select_related("follower")
        users = [f.follower for f in follows]
        return Response(PublicUserSummarySerializer(users, many=True, context={"request": request}).data)

    @action(detail=False, methods=["get"], url_path="following")
    def following(self, request):
        """Perfiles de artista que sigue el usuario autenticado."""
        follows = Follow.objects.filter(follower=request.user, artist__is_public=True).select_related("artist")
        profiles = [f.artist for f in follows]
        return Response(ArtistProfileSummarySerializer(profiles, many=True, context={"request": request}).data)

    @action(detail=True, methods=["post"], url_path="follow")
    @transaction.atomic
    def follow(self, request, slug=None):
        profile = self.get_object()
        if not request.user.is_authenticated:
            return Response({"detail": "Autenticación requerida."}, status=401)
        if profile.user_id == request.user.id:
            return Response({"detail": "No puedes seguir tu propio perfil."}, status=400)
        follow, created = Follow.objects.get_or_create(follower=request.user, artist=profile)
        if not created:
            follow.delete()
            ArtistProfile.objects.filter(id=profile.id).update(followers_count=F("followers_count") - 1)
            return Response({"detail": "Dejaste de seguir al artista."})
        ArtistProfile.objects.filter(id=profile.id).update(followers_count=F("followers_count") + 1)
        return Response({"detail": "Ahora sigues al artista."}, status=status.HTTP_201_CREATED)

