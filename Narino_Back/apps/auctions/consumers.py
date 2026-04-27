import json

from asgiref.sync import async_to_sync
from channels.generic.websocket import WebsocketConsumer

from apps.auctions.models import Auction


class AuctionConsumer(WebsocketConsumer):
    def connect(self):
        self.auction_id = self.scope["url_route"]["kwargs"]["auction_id"]
        self.group_name = f"auction_{self.auction_id}"

        async_to_sync(self.channel_layer.group_add)(self.group_name, self.channel_name)
        self.accept()
        self.send(text_data=json.dumps({"type": "connected", "auction_id": self.auction_id}))

        auction = Auction.objects.filter(id=self.auction_id).select_related("highest_bidder").first()
        if auction:
            self.send(
                text_data=json.dumps(
                    {
                        "type": "snapshot",
                        "current_price": str(auction.current_price),
                        "highest_bidder_id": str(auction.highest_bidder_id) if auction.highest_bidder_id else None,
                        "status": auction.status,
                        "ends_at": auction.ends_at.isoformat(),
                    }
                )
            )

    def disconnect(self, close_code):
        async_to_sync(self.channel_layer.group_discard)(self.group_name, self.channel_name)

    def receive(self, text_data=None, bytes_data=None):
        return

    def auction_event(self, event):
        self.send(text_data=json.dumps(event["payload"]))

