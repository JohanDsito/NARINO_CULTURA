from django.contrib import admin

from apps.musicians.models import MusicGenre, MusicianFollower, MusicianProfile, MusicianReview, MusicalWork


@admin.register(MusicGenre)
class MusicGenreAdmin(admin.ModelAdmin):
    list_display = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}
    search_fields = ("name",)


@admin.register(MusicianProfile)
class MusicianProfileAdmin(admin.ModelAdmin):
    list_display = ("artistic_name", "aggregation_type", "city", "is_verified", "is_active", "followers_count", "popularity_score")
    list_filter = ("aggregation_type", "is_verified", "is_active", "city")
    search_fields = ("artistic_name", "user__email", "city")
    filter_horizontal = ("genres",)
    readonly_fields = ("slug", "followers_count", "popularity_score", "created_at", "updated_at")
    actions = ["verify_musicians"]

    @admin.action(description="Verificar músicos seleccionados")
    def verify_musicians(self, request, queryset):
        queryset.update(is_verified=True)


@admin.register(MusicalWork)
class MusicalWorkAdmin(admin.ModelAdmin):
    list_display = ("title", "musician", "work_type", "views_count", "is_featured", "created_at")
    list_filter = ("work_type", "is_featured")
    search_fields = ("title", "musician__artistic_name")


@admin.register(MusicianReview)
class MusicianReviewAdmin(admin.ModelAdmin):
    list_display = ("musician", "reviewer", "rating", "created_at")
    list_filter = ("rating",)
    search_fields = ("musician__artistic_name", "reviewer__email")
