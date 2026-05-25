import logging
import httpx
from django.conf import settings
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.musicians.models import MusicianProfile
from apps.musicians.serializers import MusicianProfileListSerializer
from services.ai_client import AIServiceClient, AIServiceException

logger = logging.getLogger(__name__)


class MusicRecommendationView(APIView):
    """
    Natural language music discovery endpoint.
    Accepts a free-text query and returns matching musician profiles.

    With AI_SERVICE_URL configured: delegates NLP parsing to FastAPI microservice.
    Fallback: simple keyword matching against genre/city/aggregation_type fields.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        query = (request.data.get("query") or "").strip()
        if not query:
            return Response({"detail": "El campo 'query' es requerido."}, status=400)

        filters = self._parse_with_ai(query) if settings.AI_SERVICE_URL else {}
        if not filters:
            filters = self._parse_locally(query)

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

    def _parse_with_ai(self, query: str) -> dict:
        try:
            with httpx.Client(timeout=5) as client:
                response = client.post(
                    f"{settings.AI_SERVICE_URL}/music/recommendations",
                    json={"query": query},
                )
            if response.status_code == 200:
                return response.json()
        except Exception:
            pass
        return {}

    def _parse_locally(self, query: str) -> dict:
        q = query.lower()
        filters = {}

        genre_keywords = {
            "rock": "Rock", "metal": "Metal", "salsa": "Salsa", "cumbia": "Cumbia",
            "vallenato": "Vallenato", "pop": "Pop", "hip hop": "Hip Hop", "rap": "Rap",
            "jazz": "Jazz", "blues": "Blues", "electrónica": "Electrónica",
            "electronica": "Electrónica", "reggaeton": "Reggaetón", "reggae": "Reggae",
            "andina": "Música Andina", "andino": "Música Andina", "folklor": "Folclore",
            "folclore": "Folclore", "indie": "Indie", "alternativo": "Rock Alternativo",
            "chirimía": "Chirimía", "chirimia": "Chirimía", "bambuco": "Bambuco",
            "pasillo": "Pasillo", "marimba": "Marimba", "cumbia nariñense": "Cumbia Nariñense",
        }

        found_genres = []
        for kw, genre_name in genre_keywords.items():
            if kw in q:
                found_genres.append(genre_name)
        if found_genres:
            filters["genres"] = found_genres

        city_keywords = {
            "pasto": "Pasto", "ipiales": "Ipiales", "tumaco": "Tumaco",
            "túquerres": "Túquerres", "tuperres": "Túquerres", "la unión": "La Unión",
            "nariño": "Nariño",
        }
        for kw, city in city_keywords.items():
            if kw in q:
                if city == "Nariño":
                    filters["region"] = city
                else:
                    filters["city"] = city
                break

        type_keywords = {
            "banda": "BANDA", "solista": "SOLISTA", "dj": "DJ",
            "colectivo": "COLECTIVO", "dúo": "DUO", "duo": "DUO",
            "trío": "TRIO", "trio": "TRIO",
        }
        for kw, agg_type in type_keywords.items():
            if kw in q:
                filters["aggregation_type"] = agg_type
                break

        return filters


class ChatAPIView(APIView):
    """
    Endpoint de chat conversacional con IA.
    Mantiene historial de conversación y proporciona recomendaciones
    personalizadas de artistas, obras y eventos culturales.

    Autenticación: Requerida
    Rate Limit: 10 mensajes/minuto por usuario
    """

    permission_classes = [IsAuthenticated]
    ai_client = AIServiceClient()

    def post(self, request):
        """
        Envía mensaje al chat conversacional.

        Request:
        {
            "message": "¿Qué artistas de rock tienes?",
            "history": [
                {"role": "user", "text": "Hola"},
                {"role": "model", "text": "¡Hola!"}
            ]
        }

        Response:
        {
            "reply": "En Nariño tenemos excelentes bandas de rock...",
            "session_id": "user-123",
            "model_used": "gemini|rule-based"
        }
        """
        message = (request.data.get("message") or "").strip()
        if not message:
            return Response(
                {"detail": "El campo 'message' es requerido."},
                status=400
            )

        # Limitar tamaño del mensaje
        if len(message) > 500:
            return Response(
                {"detail": "El mensaje no puede exceder 500 caracteres."},
                status=400
            )

        session_id = f"user-{request.user.id}"
        history = request.data.get("history", [])

        try:
            response = self.ai_client.chat(message, session_id, history)
            return Response(response, status=200)
        except AIServiceException as e:
            logger.warning(f"AI Service error: {str(e)}")
            return Response(
                {
                    "detail": "Servicio de IA no disponible. Intenta más tarde.",
                    "reply": self._fallback_response(message)
                },
                status=503
            )
        except ValueError as e:
            logger.error(f"Invalid request: {str(e)}")
            return Response(
                {"detail": str(e)},
                status=400
            )
        except Exception as e:
            logger.error(f"Unexpected error in chat: {str(e)}")
            return Response(
                {"detail": "Error interno del servidor."},
                status=500
            )

    @staticmethod
    def _fallback_response(message: str) -> str:
        """
        Proporciona respuesta fallback cuando AI Service no está disponible.
        """
        msg_lower = message.lower()

        if any(word in msg_lower for word in ["hola", "hi", "buenos"]):
            return (
                "¡Hola! Bienvenido a Nariño Cultura. "
                "Aunque el servicio de IA está en mantenimiento, puedo ayudarte. "
                "¿Qué tipo de artistas o eventos te interesan?"
            )
        if any(word in msg_lower for word in ["artista", "músico"]):
            return "Tenemos una comunidad vibrant de artistas en Nariño. ¿Un género específico?"
        if any(word in msg_lower for word in ["evento", "concierto"]):
            return "En Nariño hay eventos culturales constantemente. ¿Qué tipo te interesa?"

        return "Estoy aquí para ayudarte. ¿Qué buscas en Nariño Cultura?"
