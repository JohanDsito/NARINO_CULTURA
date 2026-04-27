from django.conf import settings
from django.db import models

from utils.models import TimeStampedUUIDModel


class Event(TimeStampedUUIDModel):
    class Type(models.TextChoices):
        CONCIERTO = "CONCIERTO", "Concierto"
        EXPOSICION = "EXPOSICION", "Exposición"
        TALLER = "TALLER", "Taller"
        FERIA = "FERIA", "Feria"
        ESPECTACULO = "ESPECTACULO", "Espectáculo"
        OTRO = "OTRO", "Otro"

    organizer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    event_type = models.CharField(max_length=20, choices=Type.choices)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    location = models.CharField(max_length=255, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    image_url = models.URLField(blank=True)
    is_published = models.BooleanField(default=False)

    class Meta:
        ordering = ["-start_date"]
        indexes = [
            models.Index(fields=["is_published", "-start_date"]),
            models.Index(fields=["event_type", "-start_date"]),
        ]

    def __str__(self):
        return self.title


class EventRegistration(TimeStampedUUIDModel):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name="registrations")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["event", "user"], name="uniq_event_user_registration")
        ]
        indexes = [models.Index(fields=["event", "-created_at"])]

    def __str__(self):
        return f"{self.event_id} - {self.user_id}"

