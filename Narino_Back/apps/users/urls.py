from django.urls import path

from apps.users import views


urlpatterns = [
    path("auth/register/", views.RegisterAPIView.as_view()),
    path("auth/verify-email/", views.VerifyEmailAPIView.as_view()),
    path("auth/login/", views.LoginAPIView.as_view()),
    path("auth/token/refresh/", views.TokenRefreshAPIView.as_view()),
    path("auth/logout/", views.LogoutAPIView.as_view()),
    path("auth/password-reset/", views.PasswordResetRequestAPIView.as_view()),
    path("auth/password-reset/confirm/", views.PasswordResetConfirmAPIView.as_view()),
    path("users/me/", views.MeAPIView.as_view()),
    path("users/me/password/", views.MePasswordAPIView.as_view()),
]

