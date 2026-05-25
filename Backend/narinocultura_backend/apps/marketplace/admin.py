from django.contrib import admin

from apps.marketplace.models import Cart, CartItem, Favorite, Order, OrderItem


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ("user", "created_at")
    search_fields = ("user__email",)


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ("cart", "artwork", "created_at")
    search_fields = ("cart__user__email", "artwork__title")


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ("user", "artwork", "created_at")
    search_fields = ("user__email", "artwork__title")


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("id", "buyer", "status", "total_amount", "order_type", "created_at")
    search_fields = ("id", "buyer__email")
    list_filter = ("status", "order_type")
    inlines = [OrderItemInline]


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ("order", "artwork", "price")
    search_fields = ("order__id", "artwork__title")

