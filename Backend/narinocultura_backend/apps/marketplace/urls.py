from django.urls import path

from apps.marketplace import views


urlpatterns = [
    path("marketplace/cart/", views.CartAPIView.as_view()),
    path("marketplace/cart/items/", views.CartItemsAPIView.as_view()),
    path("marketplace/checkout/", views.CheckoutAPIView.as_view()),
    path("marketplace/orders/", views.OrdersAPIView.as_view()),
    path("marketplace/sales/", views.SalesAPIView.as_view()),
    path("marketplace/favorites/", views.FavoritesAPIView.as_view()),
]

