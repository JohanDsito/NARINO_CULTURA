import logging

from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.musicians.models import MusicianProfile
from apps.musicians.serializers import MusicianProfileListSerializer
from services.ai_service import AIService
from utils.http import client_ip

logger = logging.getLogger(__name__)


class MusicRecommendationView(APIView):
    """
    Natural language music discovery endpoint.
    Accepts a free-text query and returns matching musician profiles.

    La consulta la interpreta la IA (Gemini/Groq) y, sin IA disponible, un análisis
    por palabras clave de género, ciudad y tipo de agrupación.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        query = (request.data.get("query") or "").strip()
        if not query:
            return Response({"detail": "El campo 'query' es requerido."}, status=400)

        filters = AIService.music_filters(query)

        qs = MusicianProfile.objects.filter(is_active=True).prefetch_related("genres")

        genre_names = filters.get("genres", [])
        if genre_names:
            qs = qs.filter(genres__name__in=genre_names).distinct()

        city = filters.get("city", "")
        if city:
            qs = qs.filter(city__icontains=city)

        region = filters.get("region", "")
        if region:
            qs = qs.filter(region__icontains=region)

        aggregation_type = filters.get("aggregation_type", "")
        if aggregation_type:
            qs = qs.filter(aggregation_type=aggregation_type)

        if not genre_names and not city and not region and not aggregation_type:
            qs = qs.filter(artistic_name__icontains=query) | qs.filter(
                bio__icontains=query
            )
            qs = qs.distinct()

        qs = qs.order_by("-popularity_score")[:20]
        serializer = MusicianProfileListSerializer(qs, many=True)
        return Response(
            {
                "query": query,
                "filters_applied": filters,
                "count": len(serializer.data),
                "results": serializer.data,
            }
        )


class ChatAPIView(APIView):
    """
    Endpoint de chat conversacional con IA.
    Mantiene historial de conversación y proporciona recomendaciones
    personalizadas de artistas, obras y eventos culturales.

    Autenticación: Opcional (el widget se muestra también a visitantes anónimos)
    Rate Limit: 10 mensajes/minuto por usuario (o por IP si es anónimo)
    """

    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "chat"

    def post(self, request):
        """
        Request: {"message": "¿Qué bandas de rock hay?", "history": [{"role": "user"|"model", "text": "..."}]}
        Response: {"reply": "...", "session_id": "user-<id>", "model_used": "gemini"|"groq"|"rule-based"}

        Si la IA no está disponible (sin llaves o sin cuota) responde igual, con reglas.
        """
        message = (request.data.get("message") or "").strip()
        if not message:
            return Response({"detail": "El campo 'message' es requerido."}, status=400)
        if len(message) > 500:
            return Response({"detail": "El mensaje no puede exceder 500 caracteres."}, status=400)

        if request.user.is_authenticated:
            session_id = f"user-{request.user.id}"
        else:
            session_id = f"anon-{client_ip(request) or 'unknown'}"
        return Response(AIService.chat(message, session_id=session_id, history=request.data.get("history")))
