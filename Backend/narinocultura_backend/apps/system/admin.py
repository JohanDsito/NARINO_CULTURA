from django.contrib import admin

from apps.system.models import ActivityLog


@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = ("created_at", "user", "action", "entity_type", "entity_id", "ip_address")
    search_fields = ("action", "entity_type", "entity_id", "ip_address", "user__email")
    list_filter = ("entity_type",)

