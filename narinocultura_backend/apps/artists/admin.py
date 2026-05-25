from django.contrib import admin

from apps.artists.models import ArtistProfile, Follow


@admin.register(ArtistProfile)
class ArtistProfileAdmin(admin.ModelAdmin):
    list_display = ("artistic_name", "slug", "user", "followers_count", "is_public")
    search_fields = ("artistic_name", "slug", "user__email")
    list_filter = ("is_public", "discipline", "city")


@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    list_display = ("created_at", "follower", "artist")
    search_fields = ("follower__email", "artist__slug")

