from django.db import models
from django.db.models import Q

from apps.artists.models import ArtistProfile
from utils.models import TimeStampedUUIDModel


class Category(models.Model):
    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=120, unique=True)
    slug = models.SlugField(unique=True, max_length=140)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Artwork(TimeStampedUUIDModel):
    class Status(models.TextChoices):
        DISPONIBLE = "DISPONIBLE", "Disponible"
        EN_SUBASTA = "EN_SUBASTA", "En subasta"
        VENDIDA = "VENDIDA", "Vendida"
        INACTIVA = "INACTIVA", "Inactiva"

    artist = models.ForeignKey(ArtistProfile, on_delete=models.CASCADE, related_name="artworks")
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    technique = models.CharField(max_length=120, blank=True)
    dimensions = models.CharField(max_length=120, blank=True)
    material = models.CharField(max_length=120, blank=True)
    price = models.DecimalField(max_digits=12, decimal_places=2)
    category = models.ForeignKey(Category, null=True, blank=True, on_delete=models.SET_NULL)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.INACTIVA)
    main_image_url = models.URLField(blank=True)
    ai_tags = models.JSONField(default=dict, blank=True)
    ai_description = models.TextField(blank=True)
    views_count = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["artist", "-created_at"]),
            models.Index(fields=["category", "-created_at"]),
            models.Index(fields=["price"]),
        ]
        constraints = [
            models.CheckConstraint(check=Q(price__gte=0), name="artwork_price_gte_0"),
        ]

    def __str__(self):
        return f"{self.title} ({self.artist_id})"


class ArtworkImage(TimeStampedUUIDModel):
    artwork = models.ForeignKey(Artwork, on_delete=models.CASCADE, related_name="images")
    image_url = models.URLField()
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "created_at"]
        constraints = [
            models.UniqueConstraint(fields=["artwork", "order"], name="uniq_artwork_image_order")
        ]
        indexes = [models.Index(fields=["artwork", "order"])]

    def __str__(self):
        return f"{self.artwork_id} - {self.order}"

