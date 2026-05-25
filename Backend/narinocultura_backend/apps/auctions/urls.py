from rest_framework.routers import DefaultRouter

from apps.auctions.views import AuctionViewSet

router = DefaultRouter()
router.register(r"auctions", AuctionViewSet, basename="auctions")

urlpatterns = router.urls

