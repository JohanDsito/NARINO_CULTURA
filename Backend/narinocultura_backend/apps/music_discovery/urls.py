from django.urls import path

from apps.music_discovery.views import ChatAPIView, MusicRecommendationView

urlpatterns = [
    path("music-discovery/recommendations/", MusicRecommendationView.as_view(), name="music-recommendations"),
    path("chat/", ChatAPIView.as_view(), name="chat"),
]
