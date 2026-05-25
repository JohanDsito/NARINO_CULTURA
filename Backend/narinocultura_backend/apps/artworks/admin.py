from django.contrib import admin

from apps.artworks.models import Artwork, ArtworkImage, Category


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "slug")
    search_fields = ("name", "slug")


class ArtworkImageInline(admin.TabularInline):
    model = ArtworkImage
    extra = 0


@admin.register(Artwork)
class ArtworkAdmin(admin.ModelAdmin):
    list_display = ("title", "artist", "status", "price", "created_at")
    search_fields = ("title", "artist__slug")
    list_filter = ("status", "category")
    inlines = [ArtworkImageInline]

