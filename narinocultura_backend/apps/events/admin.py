from django.contrib import admin

from apps.events.models import Event, EventRegistration


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ("title", "event_type", "start_date", "end_date", "is_published")
    search_fields = ("title", "location")
    list_filter = ("event_type", "is_published")


@admin.register(EventRegistration)
class EventRegistrationAdmin(admin.ModelAdmin):
    list_display = ("event", "user", "created_at")
    search_fields = ("event__title", "user__email")

