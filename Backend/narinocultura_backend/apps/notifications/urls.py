from django.urls import path

from apps.notifications.views import (
    NotificationListAPIView,
    NotificationMarkAllReadAPIView,
    NotificationMarkReadAPIView,
    NotificationUnreadCountAPIView,
)

urlpatterns = [
    path("notifications/", NotificationListAPIView.as_view(), name="notifications-list"),
    path("notifications/unread-count/", NotificationUnreadCountAPIView.as_view(), name="notifications-unread-count"),
    path("notifications/read-all/", NotificationMarkAllReadAPIView.as_view(), name="notifications-read-all"),
    path("notifications/<uuid:pk>/read/", NotificationMarkReadAPIView.as_view(), name="notifications-read"),
]
