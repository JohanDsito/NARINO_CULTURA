from django.db import transaction
from django.db.models import F
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.musicians.models import MusicGenre, MusicianFollower, MusicianProfile, MusicianReview, MusicalWork
from apps.musicians.serializers import (
    MusicGenreSerializer,
    MusicianProfileListSerializer,
    MusicianProfileSerializer,
    MusicianReviewSerializer,
    MusicalWorkSerializer,
)


class MusicGenreViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MusicGenre.objects.all()
    serializer_class = MusicGenreSerializer
    permission_classes = [AllowAny]
    pagination_class = None


class MusicianProfileViewSet(viewsets.ModelViewSet):
    lookup_field = "slug"
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ["aggregation_type", "city", "region", "is_verified"]
    search_fields = ["artistic_name", "bio", "city", "genres__name"]
    ordering_fields = ["popularity_score", "followers_count", "created_at"]
    ordering = ["-popularity_score"]

    def get_serializer_class(self):
        if self.action == "list":
            return MusicianProfileListSerializer
        return MusicianProfileSerializer

    def get_permissions(self):
        # works and reviews (GET) are public; POST auth is checked inside the method
        if self.action in {"list", "retrieve", "works", "reviews"}:
            return [AllowAny()]
        return [IsAuthenticated()]

    # Actions where any user can look up the profile by slug (active only)
    PUBLIC_DETAIL_ACTIONS = {"retrieve", "follow", "works", "add_work", "reviews"}

    def get_queryset(self):
        qs = MusicianProfile.objects.select_related("user").prefetch_related("genres")
        if self.action in {"list"} | self.PUBLIC_DETAIL_ACTIONS:
            qs = qs.filter(is_active=True)
            if self.action == "list":
                genre_slug = self.request.query_params.get("genre")
                if genre_slug:
                    qs = qs.filter(genres__slug=genre_slug)
            return qs
        # update / partial_update / destroy / me — own profile only
        return qs.filter(user=self.request.user)

    @action(detail=True, methods=["post"], url_path="follow", permission_classes=[IsAuthenticated])
    @transaction.atomic
    def follow(self, request, slug=None):
        profile = self.get_object()
        if profile.user_id == request.user.id:
            return Response(
                {"detail": "No puedes seguirte a ti mismo."}, status=status.HTTP_400_BAD_REQUEST
            )
        follower, created = MusicianFollower.objects.get_or_create(
            user=request.user, musician=profile
        )
        if not created:
            follower.delete()
            MusicianProfile.objects.filter(pk=profile.pk).update(
                followers_count=F("followers_count") - 1
            )
            return Response({"detail": "Dejaste de seguir al músico.", "following": False})
        MusicianProfile.objects.filter(pk=profile.pk).update(
            followers_count=F("followers_count") + 1
        )
        return Response(
            {"detail": "Ahora sigues a este músico.", "following": True},
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["get"], url_path="works", permission_classes=[AllowAny])
    def works(self, request, slug=None):
        profile = self.get_object()
        qs = profile.works.all()
        work_type = request.query_params.get("type")
        if work_type:
            qs = qs.filter(work_type=work_type)
        serializer = MusicalWorkSerializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=["post"], url_path="works/add", permission_classes=[IsAuthenticated])
    def add_work(self, request, slug=None):
        profile = self.get_object()
        if profile.user_id != request.user.id:
            return Response(
                {"detail": "Solo puedes agregar obras a tu propio perfil."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = MusicalWorkSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(musician=profile)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["get", "post"], url_path="reviews", permission_classes=[AllowAny])
    def reviews(self, request, slug=None):
        profile = self.get_object()
        if request.method == "GET":
            qs = profile.reviews.select_related("reviewer").all()
            serializer = MusicianReviewSerializer(qs, many=True)
            return Response(serializer.data)
        if not request.user.is_authenticated:
            return Response({"detail": "Autenticación requerida."}, status=status.HTTP_401_UNAUTHORIZED)
        serializer = MusicianReviewSerializer(
            data=request.data,
            context={"request": request, "musician": profile},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(
        detail=False,
        methods=["get"],
        url_path="me",
        permission_classes=[IsAuthenticated],
    )
    def me(self, request):
        try:
            profile = MusicianProfile.objects.prefetch_related("genres").get(user=request.user)
        except MusicianProfile.DoesNotExist:
            return Response({"detail": "No tienes perfil de músico."}, status=status.HTTP_404_NOT_FOUND)
        serializer = MusicianProfileSerializer(profile, context={"request": request})
        return Response(serializer.data)


class MusicalWorkViewSet(viewsets.ModelViewSet):
    serializer_class = MusicalWorkSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return MusicalWork.objects.filter(musician__user=self.request.user)

    def perform_create(self, serializer):
        """Asigna automáticamente el músico del usuario actual."""
        try:
            musician = MusicianProfile.objects.get(user=self.request.user)
            serializer.save(musician=musician)
        except MusicianProfile.DoesNotExist:
            return Response(
                {"detail": "Necesitas crear un perfil de músico primero."},
                status=status.HTTP_400_BAD_REQUEST,
            )

    @action(detail=True, methods=["post"], url_path="view")
    def register_view(self, request, pk=None):
        MusicalWork.objects.filter(pk=pk).update(views_count=F("views_count") + 1)
        return Response({"detail": "Vista registrada."})
