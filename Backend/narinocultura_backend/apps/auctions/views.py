from django.db.models import Count, Q
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.auctions.models import Auction, Bid
from apps.auctions.permissions import IsAuctionSellerOrAdmin
from apps.auctions.serializers import AuctionSerializer, BidCreateSerializer, BidHistorySerializer
from services.auction_service import AuctionService
from utils.exceptions import BusinessLogicError
from utils.permissions import IsAdmin


class AuctionViewSet(viewsets.ModelViewSet):
    serializer_class = AuctionSerializer
    filterset_fields = ("status",)

    def get_permissions(self):
        if self.action in {"list", "retrieve"}:
            return [AllowAny()]
        if self.action in {"update", "partial_update", "destroy"}:
            return [IsAuthenticated(), IsAuctionSellerOrAdmin()]
        return super().get_permissions()

    def get_queryset(self):
        qs = Auction.objects.select_related(
            "artwork", "artwork__artist", "seller", "highest_bidder", "winner"
        ).annotate(bids_total=Count("bids"))
        user = self.request.user
        if not (user.is_authenticated and user.role == "ADMINISTRADOR"):
            # Las subastas pendientes de aprobación solo las ve su vendedor (y el admin)
            visible = ~Q(status=Auction.Status.PENDIENTE)
            if user.is_authenticated:
                visible |= Q(seller=user)
            qs = qs.filter(visible)
        if self.action == "list":
            qs = self._filter_by_user(qs, user)
        return qs

    def _filter_by_user(self, qs, user):
        """?mine=true: subastas que vendo. ?participating=true: subastas en las que pujé (gane o no)."""
        params = self.request.query_params
        mine = params.get("mine", "").lower() == "true"
        participating = params.get("participating", "").lower() == "true"
        if (mine or participating) and not user.is_authenticated:
            return qs.none()
        if mine:
            qs = qs.filter(seller=user)
        if participating:
            qs = qs.filter(id__in=Bid.objects.filter(bidder=user).values("auction_id"))
        return qs

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

    def _ensure_pending(self, auction):
        # Una subasta activa ya tiene postores y la obra EN_SUBASTA: se gestiona con close o reject.
        if auction.status != Auction.Status.PENDIENTE:
            raise BusinessLogicError("Solo se pueden modificar o eliminar subastas en estado PENDIENTE.")

    def perform_update(self, serializer):
        auction = serializer.instance
        self._ensure_pending(auction)
        artwork = serializer.validated_data.get("artwork")
        if artwork is not None and artwork.id != auction.artwork_id:
            raise ValidationError({"artwork": "La obra de una subasta no se puede cambiar."})
        extra = {}
        if "base_price" in serializer.validated_data:
            # Sin pujas todavía, el precio actual sigue al precio base
            extra["current_price"] = serializer.validated_data["base_price"]
        serializer.save(**extra)

    def perform_destroy(self, instance):
        self._ensure_pending(instance)
        instance.delete()

    @action(detail=True, methods=["get"], url_path="bids", permission_classes=[AllowAny])
    def bids(self, request, pk=None):
        """Historial de pujas, de la más reciente a la más antigua."""
        auction = self.get_object()
        qs = auction.bids.select_related("bidder").order_by("-created_at")
        page = self.paginate_queryset(qs)
        serializer = BidHistorySerializer(page if page is not None else qs, many=True, context={"request": request})
        return self.get_paginated_response(serializer.data) if page is not None else Response(serializer.data)

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

    @action(detail=True, methods=["post"], url_path="approve", permission_classes=[IsAdmin])
    def approve(self, request, pk=None):
        auction = self.get_object()
        try:
            AuctionService.approve_auction(auction=auction, actor=request.user)
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"detail": "Subasta aprobada y activada."})

    @action(detail=True, methods=["post"], url_path="reject", permission_classes=[IsAdmin])
    def reject(self, request, pk=None):
        auction = self.get_object()
        try:
            AuctionService.reject_auction(auction=auction, actor=request.user)
        except ValueError as e:
            return Response({"detail": str(e)}, status=400)
        return Response({"detail": "Subasta rechazada."})

