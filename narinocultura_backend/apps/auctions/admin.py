from django.contrib import admin

from apps.auctions.models import Auction, Bid


@admin.register(Auction)
class AuctionAdmin(admin.ModelAdmin):
    list_display = ("id", "artwork", "status", "current_price", "starts_at", "ends_at")
    list_filter = ("status",)
    search_fields = ("id", "artwork__title", "seller__email")


@admin.register(Bid)
class BidAdmin(admin.ModelAdmin):
    list_display = ("created_at", "auction", "bidder", "amount")
    search_fields = ("auction__id", "bidder__email")

