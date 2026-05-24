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
