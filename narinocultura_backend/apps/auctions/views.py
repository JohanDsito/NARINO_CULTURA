from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.auctions.models import Auction
from apps.auctions.serializers import AuctionSerializer, BidCreateSerializer
from services.auction_service import AuctionService


class AuctionViewSet(viewsets.ModelViewSet):
    serializer_class = AuctionSerializer

    def get_permissions(self):
        if self.action in {"list", "retrieve"}:
            return [AllowAny()]
        return super().get_permissions()

    def get_queryset(self):
        return (
            Auction.objects.select_related("artwork", "seller", "highest_bidder", "winner")
            .prefetch_related("bids")
        )

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            self.perform_create(serializer)
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        auction = AuctionService.create_auction(
            seller=self.request.user,
            artwork=serializer.validated_data["artwork"],
            base_price=serializer.validated_data["base_price"],
            starts_at=serializer.validated_data["starts_at"],
            ends_at=serializer.validated_data["ends_at"],
        )
        serializer.instance = auction

    @action(detail=True, methods=["post"], url_path="bid")
    def bid(self, request, pk=None):
        auction = self.get_object()
        serializer = BidCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            bid = AuctionService.place_bid(
                auction=auction,
                bidder=request.user,
                amount=serializer.validated_data["amount"],
            )
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"detail": "Puja registrada.", "bid_id": str(bid.id)}, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"], url_path="close")
    def close(self, request, pk=None):
        auction = self.get_object()
        try:
            AuctionService.close_auction(auction=auction, actor=request.user)
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"detail": "Subasta cerrada."})

