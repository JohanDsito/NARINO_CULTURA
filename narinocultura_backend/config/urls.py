from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.system.views import HealthCheckAPIView


def api_root(request):
    return JsonResponse(
        {
            "message": "Bienvenido a Narino Cultura API",
            "version": "1.0.0",
            "docs": "/api/docs/",
            "health": "/health/",
            "endpoints": {
                "admin": "/admin/",
                "api": "/api/v1/",
            },
        }
    )


urlpatterns = [
    path("", api_root, name="api-root"),
    path("health/", HealthCheckAPIView.as_view(), name="health-check"),
    # OpenAPI schema + Swagger UI
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path("admin/", admin.site.urls),
    path("api/v1/", include("apps.users.urls")),
    path("api/v1/", include("apps.artists.urls")),
    path("api/v1/", include("apps.artworks.urls")),
    path("api/v1/", include("apps.marketplace.urls")),
    path("api/v1/", include("apps.auctions.urls")),
    path("api/v1/", include("apps.payments.urls")),
    path("api/v1/", include("apps.events.urls")),
    path("api/v1/", include("apps.administration.urls")),
    path("api/v1/", include("apps.musicians.urls")),
    path("api/v1/", include("apps.music_discovery.urls")),
] + static(settings.MEDIA_URL, document_root=getattr(settings, "MEDIA_ROOT", None))
