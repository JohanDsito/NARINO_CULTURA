from django.db import transaction
from django.db.models import Count, Exists, F, OuterRef, Q
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.artists.models import ArtistProfile, Follow
from apps.artists.serializers import ArtistProfileSerializer, ArtistProfileSummarySerializer
from apps.artworks.models import PUBLIC_ARTWORK_STATUSES
from apps.users.serializers import PublicUserSummarySerializer


class ArtistProfileViewSet(viewsets.ModelViewSet):
    serializer_class = ArtistProfileSerializer
    lookup_field = "slug"

    def get_permissions(self):
        if self.action in {"list", "retrieve"}:
            return [AllowAny()]
        return super().get_permissions()

    def get_queryset(self):
        return self._with_stats(self._visible_profiles())

    def _with_stats(self, qs):
        # Obras públicas, artistas que sigue y si el usuario lo sigue, en la misma consulta
        qs = qs.annotate(
            artworks_total=Count("artworks", filter=Q(artworks__status__in=PUBLIC_ARTWORK_STATUSES), distinct=True),
            following_total=Count("user__following", distinct=True),
        )
        user = self.request.user
        if user.is_authenticated:
            qs = qs.annotate(user_follows=Exists(Follow.objects.filter(artist=OuterRef("pk"), follower=user)))
        return qs

    @action(detail=False, methods=["get"], url_path="me")
    def me(self, request):
        """Perfil de artista del usuario autenticado (antes había que buscarlo en la lista)."""
        profile = self.get_queryset().first()
        if profile is None:
            return Response({"detail": "No tienes perfil de artista."}, status=status.HTTP_404_NOT_FOUND)
        return Response(self.get_serializer(profile).data)

    def _visible_profiles(self):
        qs = ArtistProfile.objects.select_related("user")
        if self.action in {"list", "retrieve"} and not self.request.user.is_authenticated:
            return qs.filter(is_public=True)
        if self.action in {"list", "retrieve"}:
            return qs.filter(is_public=True) | qs.filter(user=self.request.user)
        if self.action == "follow":
            # Se puede seguir cualquier perfil público (no solo el propio)
            return qs.filter(is_public=True)
        # update / partial_update / destroy / followers / me — solo el perfil propio
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
            # followers_count__gt=0: un contador desincronizado nunca baja de 0 (evita un error 500)
            ArtistProfile.objects.filter(id=profile.id, followers_count__gt=0).update(followers_count=F("followers_count") - 1)
            return Response({"detail": "Dejaste de seguir al artista."})
        ArtistProfile.objects.filter(id=profile.id).update(followers_count=F("followers_count") + 1)
        return Response({"detail": "Ahora sigues al artista."}, status=status.HTTP_201_CREATED)

