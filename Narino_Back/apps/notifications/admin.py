from django.contrib import admin

from apps.notifications.models import NotificationLog


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ("sent_at", "notification_type", "status", "user")
    search_fields = ("notification_type", "user__email")
    list_filter = ("status", "notification_type")

