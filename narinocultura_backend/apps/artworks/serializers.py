from rest_framework import serializers

from apps.artworks.models import Artwork, ArtworkImage, Category


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "slug", "description")


class ArtworkImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ArtworkImage
        fields = ("id", "image_url", "order")
        read_only_fields = ("id",)


class ArtworkSerializer(serializers.ModelSerializer):
    artist_slug = serializers.CharField(source="artist.slug", read_only=True)
    images = ArtworkImageSerializer(many=True, required=False)

    class Meta:
        model = Artwork
        fields = (
            "id",
            "artist",
            "artist_slug",
            "title",
            "description",
            "technique",
            "dimensions",
            "material",
            "price",
            "category",
            "status",
            "main_image_url",
            "ai_tags",
            "ai_description",
            "views_count",
            "images",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "artist", "status", "ai_tags", "ai_description", "views_count", "created_at", "updated_at")

    def validate_price(self, value):
        if value < 0:
            raise serializers.ValidationError("El precio no puede ser negativo.")
        return value

    def create(self, validated_data):
        images_data = validated_data.pop("images", [])
        artwork = Artwork.objects.create(**validated_data)
        for image in images_data:
            ArtworkImage.objects.create(artwork=artwork, **image)
        return artwork

    def update(self, instance, validated_data):
        images_data = validated_data.pop("images", None)
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()
        if images_data is not None:
            instance.images.all().delete()
            for image in images_data:
                ArtworkImage.objects.create(artwork=instance, **image)
        return instance


class ArtworkAIEnhanceSerializer(serializers.Serializer):
    regenerate_description = serializers.BooleanField(default=False)

