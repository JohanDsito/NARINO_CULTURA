from rest_framework.routers import DefaultRouter

from apps.artists.views import ArtistProfileViewSet

router = DefaultRouter()
router.register(r"artists", ArtistProfileViewSet, basename="artists")

urlpatterns = router.urls

