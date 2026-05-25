from rest_framework.routers import DefaultRouter

from apps.musicians.views import MusicGenreViewSet, MusicianProfileViewSet, MusicalWorkViewSet

router = DefaultRouter()
router.register(r"musicians/genres", MusicGenreViewSet, basename="music-genre")
router.register(r"musicians/works", MusicalWorkViewSet, basename="musical-work")
router.register(r"musicians", MusicianProfileViewSet, basename="musician")

urlpatterns = router.urls
