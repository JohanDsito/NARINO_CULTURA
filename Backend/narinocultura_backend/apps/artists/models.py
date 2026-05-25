from django.conf import settings
from django.db import models
from django.utils.text import slugify

from utils.models import TimeStampedUUIDModel


class ArtistProfile(TimeStampedUUIDModel):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    slug = models.SlugField(unique=True, max_length=120)
    artistic_name = models.CharField(max_length=120)
    bio = models.TextField(blank=True)
    trajectory = models.TextField(blank=True)
    discipline = models.CharField(max_length=120, blank=True)
    city = models.CharField(max_length=120, blank=True)
    website_url = models.URLField(blank=True)
    instagram_url = models.URLField(blank=True)
    facebook_url = models.URLField(blank=True)
    tiktok_url = models.URLField(blank=True)
    followers_count = models.PositiveIntegerField(default=0)
    is_public = models.BooleanField(default=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["slug"]), models.Index(fields=["is_public"])]

    def __str__(self):
        return self.artistic_name

    @staticmethod
    def generate_unique_slug(artistic_name: str) -> str:
        base = slugify(artistic_name)[:110] or "artista"
        slug = base
        i = 1
        while ArtistProfile.objects.filter(slug=slug).exists():
            i += 1
            slug = f"{base}-{i}"
        return slug


class Follow(TimeStampedUUIDModel):
    follower = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="following"
    )
    artist = models.ForeignKey(
        ArtistProfile, on_delete=models.CASCADE, related_name="followers"
    )

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["follower", "artist"], name="uniq_follow_follower_artist")
        ]
        indexes = [models.Index(fields=["artist", "-created_at"])]

    def __str__(self):
        return f"{self.follower_id} -> {self.artist_id}"

