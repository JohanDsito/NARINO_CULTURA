from rest_framework.routers import DefaultRouter

from apps.artworks.views import ArtworkViewSet, CategoryViewSet

router = DefaultRouter()
router.register(r"artworks/categories", CategoryViewSet, basename="categories")
router.register(r"artworks", ArtworkViewSet, basename="artworks")

urlpatterns = router.urls

