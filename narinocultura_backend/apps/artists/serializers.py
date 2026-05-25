from rest_framework import serializers

from apps.artists.models import ArtistProfile, Follow


class ArtistProfileSerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(source="user.id", read_only=True)

    class Meta:
        model = ArtistProfile
        fields = (
            "id",
            "user_id",
            "slug",
            "artistic_name",
            "bio",
            "trajectory",
            "discipline",
            "city",
            "website_url",
            "instagram_url",
            "facebook_url",
            "tiktok_url",
            "followers_count",
            "is_public",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "user_id", "slug", "followers_count", "created_at", "updated_at")

    def validate(self, attrs):
        request = self.context.get("request")
        if request and request.method == "POST":
            if getattr(request.user, "role", None) != "ARTISTA":
                raise serializers.ValidationError("Solo un usuario con rol ARTISTA puede crear perfil.")
            if ArtistProfile.objects.filter(user=request.user).exists():
                raise serializers.ValidationError("Este usuario ya tiene un perfil de artista.")
        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        slug = ArtistProfile.generate_unique_slug(validated_data["artistic_name"])
        return ArtistProfile.objects.create(user=request.user, slug=slug, **validated_data)


class FollowSerializer(serializers.ModelSerializer):
    class Meta:
        model = Follow
        fields = ("id", "follower", "artist", "created_at")
        read_only_fields = ("id", "follower", "artist", "created_at")

