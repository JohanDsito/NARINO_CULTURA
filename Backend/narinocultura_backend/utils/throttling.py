from rest_framework.throttling import AnonRateThrottle, UserRateThrottle


class AuthAnonThrottle(AnonRateThrottle):
    """5 requests/minute for unauthenticated auth endpoints (login, register)."""
    scope = "auth_anon"


class PasswordResetThrottle(AnonRateThrottle):
    """3 requests/hour for password reset to prevent abuse."""
    scope = "password_reset"


class StrictUserThrottle(UserRateThrottle):
    """Tighter limit for sensitive authenticated actions."""
    scope = "user"


class ResendVerificationThrottle(AnonRateThrottle):
    """3 reenvíos de verificación por hora y por IP."""
    scope = "resend_verification"


class AIBurstThrottle(UserRateThrottle):
    """Límite por minuto de los endpoints que llaman a la IA (por usuario o, si es anónimo, por IP).

    Protege la cuota gratuita de Gemini y Groq: sin él, una sola persona podría agotar la cuota
    del día y la IA quedaría respondiendo solo con reglas. Se suma a los límites globales por hora.
    """
    scope = "ai"
