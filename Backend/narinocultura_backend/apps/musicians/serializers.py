from django.db import transaction
from rest_framework import serializers

from apps.musicians.models import MusicGenre, MusicianFollower, MusicianProfile, MusicianReview, MusicalWork


class MusicGenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = MusicGenre
        fields = ("id", "name", "slug", "description", "icon")
        read_only_fields = ("id", "slug")


class MusicalWorkSerializer(serializers.ModelSerializer):
    class Meta:
        model = MusicalWork
        fields = (
            "id",
            "musician",
            "title",
            "work_type",
            "youtube_url",
            "soundcloud_embed",
            "spotify_track_url",
            "audio_file",
            "thumbnail",
            "description",
            "release_date",
            "views_count",
            "duration_seconds",
            "is_featured",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "musician", "views_count", "created_at", "updated_at")


class MusicianProfileSerializer(serializers.ModelSerializer):
    genres = MusicGenreSerializer(many=True, read_only=True)
    genre_ids = serializers.PrimaryKeyRelatedField(
        queryset=MusicGenre.objects.all(),
        many=True,
        write_only=True,
        source="genres",
        required=False,
    )
    user_id = serializers.UUIDField(source="user.id", read_only=True)
    works_count = serializers.SerializerMethodField()
    profile_image_url = serializers.SerializerMethodField(read_only=True)
    profile_image = serializers.FileField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = MusicianProfile
        fields = (
            "id",
            "user_id",
            "artistic_name",
            "slug",
            "aggregation_type",
            "city",
            "region",
            "bio",
            "founding_year",
            "genres",
            "genre_ids",
            "spotify_url",
            "youtube_url",
            "soundcloud_url",
            "apple_music_url",
            "instagram_handle",
            "tiktok_handle",
            "website_url",
            "contact_email",
            "booking_email",
            "phone",
            "profile_image",
            "profile_image_url",
            "is_verified",
            "is_active",
            "followers_count",
            "popularity_score",
            "works_count",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "user_id",
            "slug",
            "is_verified",
            "followers_count",
            "popularity_score",
            "created_at",
            "updated_at",
        )

    def get_profile_image_url(self, obj):
        if not obj.profile_image:
            return ""
        request = self.context.get("request")
        return request.build_absolute_uri(obj.profile_image.url) if request else obj.profile_image.url

    def get_works_count(self, obj):
        return obj.works.count()

    def validate(self, attrs):
        request = self.context.get("request")
        if request and request.method == "POST":
            if MusicianProfile.objects.filter(user=request.user).exists():
                raise serializers.ValidationError(
                    "Ya tienes un perfil de músico registrado."
                )
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        request = self.context["request"]
        genres = validated_data.pop("genres", [])
        slug = MusicianProfile.generate_unique_slug(validated_data["artistic_name"])
        profile = MusicianProfile.objects.create(
            user=request.user, slug=slug, **validated_data
        )
        if genres:
            profile.genres.set(genres)
        return profile

    @transaction.atomic
    def update(self, instance, validated_data):
        genres = validated_data.pop("genres", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if genres is not None:
            instance.genres.set(genres)
        return instance


class MusicianProfileListSerializer(serializers.ModelSerializer):
    genres = MusicGenreSerializer(many=True, read_only=True)
    profile_image_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = MusicianProfile
        fields = (
            "id",
            "artistic_name",
            "slug",
            "aggregation_type",
            "city",
            "region",
            "bio",
            "genres",
            "profile_image_url",
            "spotify_url",
            "youtube_url",
            "instagram_handle",
            "is_verified",
            "followers_count",
            "popularity_score",
        )

    def get_profile_image_url(self, obj):
        if not obj.profile_image:
            return ""
        request = self.context.get("request")
        return request.build_absolute_uri(obj.profile_image.url) if request else obj.profile_image.url


class MusicianReviewSerializer(serializers.ModelSerializer):
    reviewer_name = serializers.SerializerMethodField()

    class Meta:
        model = MusicianReview
        fields = (
            "id",
            "musician",
            "reviewer",
            "reviewer_name",
            "rating",
            "comment",
            "created_at",
        )
        read_only_fields = ("id", "musician", "reviewer", "reviewer_name", "created_at")

    def get_reviewer_name(self, obj):
        u = obj.reviewer
        return f"{u.first_name} {u.last_name}".strip() or u.email

    def validate(self, attrs):
        request = self.context.get("request")
        musician = self.context.get("musician")
        if musician and request:
            if musician.user_id == request.user.id:
                raise serializers.ValidationError(
                    "No puedes reseñar tu propio perfil."
                )
            if MusicianReview.objects.filter(
                musician=musician, reviewer=request.user
            ).exists():
                raise serializers.ValidationError(
                    "Ya dejaste una reseña para este músico."
                )
        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        musician = self.context["musician"]
        return MusicianReview.objects.create(
            musician=musician, reviewer=request.user, **validated_data
        )
