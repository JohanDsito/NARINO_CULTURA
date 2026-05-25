from django.urls import re_path

from apps.auctions.consumers import AuctionConsumer

websocket_urlpatterns = [
    re_path(r"^ws/auctions/(?P<auction_id>[0-9a-f-]+)/$", AuctionConsumer.as_asgi()),
]

