from rest_framework import serializers

from apps.artworks.models import Artwork, ArtworkImage, Category


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ("id", "name", "slug", "description")


class ArtworkImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField(read_only=True)
    image = serializers.FileField(write_only=True, required=False, allow_null=True)

    class Meta:
        model = ArtworkImage
        fields = ("id", "image_url", "image", "order")
        read_only_fields = ("id",)

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get("request")
            url = obj.image.url
            return request.build_absolute_uri(url) if request else url
        return obj.image_url or ""


class ArtworkSerializer(serializers.ModelSerializer):
    artist_slug = serializers.CharField(source="artist.slug", read_only=True)
    images = ArtworkImageSerializer(many=True, required=False)
    main_image_url = serializers.SerializerMethodField(read_only=True)
    main_image = serializers.FileField(write_only=True, required=False, allow_null=True)
    category_detail = CategorySerializer(source="category", read_only=True)

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
            "category_detail",
            "status",
            "main_image",
            "main_image_url",
            "ai_tags",
            "ai_description",
            "views_count",
            "images",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "artist",
            "status",
            "ai_tags",
            "ai_description",
            "views_count",
            "created_at",
            "updated_at",
        )

    def get_main_image_url(self, obj):
        if obj.main_image:
            request = self.context.get("request")
            url = obj.main_image.url
            return request.build_absolute_uri(url) if request else url
        return obj.main_image_url or ""

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
