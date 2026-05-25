from django.contrib import admin

from apps.payments.models import Transaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ("id", "order", "status", "amount", "currency", "created_at")
    list_filter = ("status", "currency")
    search_fields = ("id", "order__id", "wompi_transaction_id")

