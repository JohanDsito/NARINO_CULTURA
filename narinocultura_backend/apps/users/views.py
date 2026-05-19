from django.db import transaction
from django.http import HttpResponse
from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import EmailVerification, PasswordReset, User
from apps.users.serializers import (
    EmailVerificationSerializer,
    LoginSerializer,
    LogoutSerializer,
    PasswordChangeSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UserMeSerializer,
)
from services.email_service import EmailService


class RegisterAPIView(APIView):
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save(is_active=True, is_verified=False)
        verification = EmailVerification.issue_for_user(user)

        import logging

        logger = logging.getLogger(__name__)
        logger.info(f"Intentando enviar email de verificacion a {user.email}")
        logger.info(f"Token generado: {verification.token[:10]}...")

        try:
            email_result = EmailService.send_verification_email(
                user.email,
                verification.token,
                user.first_name,
            )
            logger.info(f"Resultado del envio: {email_result.ok}")

            if not email_result.ok:
                logger.error(f"Error al enviar email: {email_result.error_message}")
                return Response(
                    {
                        "detail": (
                            "Registro creado pero hubo un error al enviar el correo: "
                            f"{email_result.error_message}"
                        )
                    },
                    status=status.HTTP_201_CREATED,
                )

            logger.info("Email de verificacion enviado exitosamente")
            return Response(
                {"detail": "Registro exitoso. Revisa tu correo para verificar la cuenta."},
                status=status.HTTP_201_CREATED,
            )
        except Exception as e:
            logger.error(f"Excepcion al enviar email: {str(e)}")
            import traceback

            logger.error(traceback.format_exc())
            return Response(
                {"detail": f"Registro creado pero hubo un error inesperado: {str(e)}"},
                status=status.HTTP_201_CREATED,
            )


class VerifyEmailAPIView(APIView):
    permission_classes = [AllowAny]

    @transaction.atomic
    def _verify_token(self, token):
        verification = (
            EmailVerification.objects.select_related("user")
            .filter(token=token, used=False)
            .first()
        )
        if not verification or not verification.is_valid():
            return False, "Token invalido o expirado."

        verification.used = True
        verification.save(update_fields=["used", "updated_at"])
        user = verification.user
        user.is_verified = True
        user.save(update_fields=["is_verified", "updated_at"])
        return True, "Email verificado correctamente."

    def get(self, request):
        token = request.query_params.get("token", "").strip()
        if not token:
            return HttpResponse(
                "<h1>Enlace invalido</h1><p>Falta el token de verificacion.</p>",
                status=400,
            )

        ok, message = self._verify_token(token)
        if not ok:
            return HttpResponse(
                f"<h1>No se pudo verificar</h1><p>{message}</p>",
                status=400,
            )

        return HttpResponse(
            "<h1>Correo verificado</h1><p>Tu cuenta fue activada correctamente. Ya puedes iniciar sesion.</p>",
            status=200,
        )

    def post(self, request):
        serializer = EmailVerificationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ok, message = self._verify_token(serializer.validated_data["token"])
        if not ok:
            return Response({"detail": message}, status=400)
        return Response({"detail": message})


class LoginAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        return Response(
            {
                "access": serializer.validated_data["access"],
                "refresh": serializer.validated_data["refresh"],
            }
        )


class TokenRefreshAPIView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        refresh = request.data.get("refresh")
        if not refresh:
            return Response({"detail": "El campo refresh es obligatorio."}, status=400)
        try:
            token = RefreshToken(refresh)
            return Response({"access": str(token.access_token)})
        except Exception:
            return Response({"detail": "Refresh token invalido."}, status=400)


class LogoutAPIView(APIView):
    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        refresh = serializer.validated_data["refresh"]
        try:
            token = RefreshToken(refresh)
            token.blacklist()
        except Exception:
            return Response(
                {"detail": "No fue posible cerrar sesion con este token."},
                status=400,
            )
        return Response({"detail": "Sesion cerrada correctamente."})


class PasswordResetRequestAPIView(APIView):
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"]
        user = User.objects.filter(email=email).first()
        if user:
            reset = PasswordReset.issue_for_user(user)
            EmailService.send_password_reset_email(user.email, reset.token)
        return Response(
            {
                "detail": (
                    "Si el email existe, se enviaron instrucciones de recuperacion."
                )
            }
        )


class PasswordResetConfirmAPIView(APIView):
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.validated_data["token"]
        new_password = serializer.validated_data["new_password"]
        reset = (
            PasswordReset.objects.select_related("user")
            .filter(token=token, used=False)
            .first()
        )
        if not reset or not reset.is_valid():
            return Response({"detail": "Token invalido o expirado."}, status=400)
        reset.used = True
        reset.save(update_fields=["used", "updated_at"])
        user = reset.user
        user.set_password(new_password)
        user.save(update_fields=["password", "updated_at"])
        return Response({"detail": "Contrasena actualizada correctamente."})


class MeAPIView(generics.RetrieveUpdateAPIView):
    serializer_class = UserMeSerializer

    def get_object(self):
        return self.request.user


class MePasswordAPIView(APIView):
    def patch(self, request):
        serializer = PasswordChangeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        current_password = serializer.validated_data["current_password"]
        new_password = serializer.validated_data["new_password"]
        if not request.user.check_password(current_password):
            return Response(
                {"detail": "La contrasena actual no es correcta."},
                status=400,
            )
        request.user.set_password(new_password)
        request.user.save(update_fields=["password", "updated_at"])
        return Response({"detail": "Contrasena actualizada correctamente."})
