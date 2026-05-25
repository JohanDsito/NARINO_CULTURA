from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils.text import slugify

from utils.models import TimeStampedUUIDModel


class MusicGenre(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=120, unique=True)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, blank=True)

    class Meta:
        ordering = ["name"]
        verbose_name = "Género Musical"
        verbose_name_plural = "Géneros Musicales"

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)


class MusicianProfile(TimeStampedUUIDModel):
    class AggregationType(models.TextChoices):
        SOLISTA = "SOLISTA", "Solista"
        BANDA = "BANDA", "Banda"
        DJ = "DJ", "DJ"
        COLECTIVO = "COLECTIVO", "Colectivo"
        DUO = "DUO", "Dúo"
        TRIO = "TRIO", "Trío"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="musician_profile",
    )
    artistic_name = models.CharField(max_length=200)
    slug = models.SlugField(max_length=220, unique=True)
    aggregation_type = models.CharField(
        max_length=20,
        choices=AggregationType.choices,
        default=AggregationType.SOLISTA,
    )
    city = models.CharField(max_length=100, default="Pasto")
    region = models.CharField(max_length=100, default="Nariño")
    bio = models.TextField(blank=True)
    founding_year = models.PositiveSmallIntegerField(null=True, blank=True)
    genres = models.ManyToManyField(MusicGenre, related_name="musicians", blank=True)

    # Plataformas de streaming y redes
    spotify_url = models.URLField(blank=True)
    youtube_url = models.URLField(blank=True)
    soundcloud_url = models.URLField(blank=True)
    apple_music_url = models.URLField(blank=True)
    instagram_handle = models.CharField(max_length=100, blank=True)
    tiktok_handle = models.CharField(max_length=100, blank=True)
    website_url = models.URLField(blank=True)

    # Contacto
    contact_email = models.EmailField(blank=True)
    booking_email = models.EmailField(blank=True)
    phone = models.CharField(max_length=30, blank=True)

    # Imagen
    profile_image = models.FileField(upload_to="musicians/profiles/", blank=True)

    # Estado y métricas
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    followers_count = models.PositiveIntegerField(default=0)
    popularity_score = models.FloatField(default=0.0)

    class Meta:
        ordering = ["-popularity_score", "-created_at"]
        indexes = [
            models.Index(fields=["slug"]),
            models.Index(fields=["city", "is_active"]),
            models.Index(fields=["aggregation_type", "is_active"]),
            models.Index(fields=["-popularity_score"]),
        ]

    def __str__(self):
        return self.artistic_name

    @staticmethod
    def generate_unique_slug(artistic_name: str) -> str:
        base = slugify(artistic_name)[:210] or "musico"
        slug = base
        i = 1
        while MusicianProfile.objects.filter(slug=slug).exists():
            i += 1
            slug = f"{base}-{i}"
        return slug

    def recalculate_popularity(self):
        score = (
            self.followers_count * 2
            + self.works.aggregate(total_views=models.Sum("views_count"))["total_views"] or 0
        )
        MusicianProfile.objects.filter(pk=self.pk).update(popularity_score=score)


class MusicalWork(TimeStampedUUIDModel):
    class WorkType(models.TextChoices):
        VIDEO = "VIDEO", "Video Musical"
        LIVE = "LIVE", "Presentación En Vivo"
        STUDIO = "STUDIO", "Grabación de Estudio"
        COVER = "COVER", "Cover / Versión"
        PODCAST = "PODCAST", "Podcast / Entrevista"

    musician = models.ForeignKey(
        MusicianProfile, on_delete=models.CASCADE, related_name="works"
    )
    title = models.CharField(max_length=255)
    work_type = models.CharField(max_length=20, choices=WorkType.choices)
    youtube_url = models.URLField(blank=True)
    soundcloud_embed = models.URLField(blank=True)
    spotify_track_url = models.URLField(blank=True)
    audio_file = models.FileField(upload_to="musicians/audio/", blank=True)
    thumbnail = models.FileField(upload_to="musicians/thumbnails/", blank=True)
    description = models.TextField(blank=True)
    release_date = models.DateField(null=True, blank=True)
    views_count = models.PositiveIntegerField(default=0)
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)
    is_featured = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["musician", "-created_at"]),
            models.Index(fields=["work_type"]),
        ]

    def __str__(self):
        return f"{self.musician.artistic_name} — {self.title}"


class MusicianFollower(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="musician_follows"
    )
    musician = models.ForeignKey(
        MusicianProfile, on_delete=models.CASCADE, related_name="followers"
    )
    followed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "musician"], name="uniq_musician_follower"
            )
        ]
        indexes = [models.Index(fields=["musician", "-followed_at"])]

    def __str__(self):
        return f"{self.user_id} -> {self.musician.artistic_name}"


class MusicianReview(TimeStampedUUIDModel):
    musician = models.ForeignKey(
        MusicianProfile, on_delete=models.CASCADE, related_name="reviews"
    )
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="musician_reviews"
    )
    rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comment = models.TextField(blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["musician", "reviewer"], name="uniq_musician_review"
            )
        ]
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["musician", "-created_at"])]

    def __str__(self):
        return f"{self.musician.artistic_name} — {self.rating}★ by {self.reviewer_id}"
