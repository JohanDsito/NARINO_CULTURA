from django.urls import path

from apps.music_discovery.views import MusicRecommendationView, ChatAPIView

urlpatterns = [
    path("music-discovery/recommendations/", MusicRecommendationView.as_view(), name="music-recommendations"),
    path("chat/", ChatAPIView.as_view(), name="chat"),
]
