from django.urls import path

from apps.administration import views


urlpatterns = [
    path("admin/users/<uuid:pk>/", views.AdminUserDetailAPIView.as_view()),
    path("admin/artworks/pending/", views.PendingArtworksAPIView.as_view()),
    path("admin/artworks/<uuid:pk>/moderate/", views.ModerateArtworkAPIView.as_view()),
    path("admin/transactions/", views.AdminTransactionsAPIView.as_view()),
    path("admin/notifications/log/", views.AdminNotificationLogAPIView.as_view()),
    path("admin/metrics/", views.AdminMetricsAPIView.as_view()),
]

