from django.urls import path

from apps.payments import views


urlpatterns = [
    path("payments/initiate/", views.InitiatePaymentAPIView.as_view()),
    path("payments/wompi-webhook/", views.WompiWebhookAPIView.as_view()),
    path("payments/transactions/", views.TransactionListAPIView.as_view()),
    path("payments/transactions/<uuid:pk>/receipt/", views.TransactionReceiptAPIView.as_view()),
]

