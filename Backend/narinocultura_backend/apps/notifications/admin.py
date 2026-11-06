from django.contrib import admin

from apps.notifications.models import Notification, NotificationLog


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ("sent_at", "notification_type", "status", "user")
    search_fields = ("notification_type", "user__email")
    list_filter = ("status", "notification_type")


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("created_at", "recipient", "notification_type", "title", "read_at")
    search_fields = ("title", "recipient__email")
    list_filter = ("notification_type",)
