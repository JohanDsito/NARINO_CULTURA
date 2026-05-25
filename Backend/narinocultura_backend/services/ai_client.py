"""
Cliente HTTP para el microservicio de IA.
Maneja comunicación con FastAPI AI Service de forma profesional.
"""
import logging
import requests
from typing import Optional, List, Dict
from django.conf import settings

logger = logging.getLogger(__name__)


class AIServiceClient:
    """
    Cliente HTTP para el microservicio de Inteligencia Artificial.
    Proporciona métodos para chat, enriquecimiento de obras y más.
    """

    DEFAULT_TIMEOUT = 15
    FALLBACK_ENABLED = True

    def __init__(self):
        self.base_url = getattr(settings, "AI_SERVICE_URL", "http://localhost:8001")
        self.timeout = self.DEFAULT_TIMEOUT

    def _request(self, method: str, endpoint: str, data: dict = None) -> dict:
        """
        Realiza petición HTTP al servicio de IA con manejo de errores.

        Args:
            method: GET, POST, etc.
            endpoint: Ruta relativa (ej: "/chat")
            data: Payload JSON

        Returns:
            dict: Respuesta JSON

        Raises:
            AIServiceException: Si el servicio no responde
        """
        url = f"{self.base_url}{endpoint}"

        try:
            if method == "POST":
                response = requests.post(
                    url,
                    json=data,
                    timeout=self.timeout,
                    headers={"Content-Type": "application/json"}
                )
            elif method == "GET":
                response = requests.get(url, timeout=self.timeout)
            else:
                raise ValueError(f"Método HTTP no soportado: {method}")

            response.raise_for_status()
            return response.json()

        except requests.exceptions.Timeout:
            logger.error(f"AI Service timeout en {endpoint}")
            raise AIServiceException("AI Service no responde a tiempo")
        except requests.exceptions.ConnectionError:
            logger.error(f"No se puede conectar a AI Service en {self.base_url}")
            raise AIServiceException("No se puede conectar a AI Service")
        except requests.exceptions.RequestException as e:
            logger.error(f"Error en petición a AI Service: {str(e)}")
            raise AIServiceException(f"Error en AI Service: {str(e)}")
        except ValueError as e:
            logger.error(f"Error al parsear JSON de AI Service: {str(e)}")
            raise AIServiceException("Respuesta inválida de AI Service")

    def health_check(self) -> bool:
        """
        Verifica que el servicio de IA esté disponible.

        Returns:
            bool: True si está disponible
        """
        try:
            response = self._request("GET", "/health")
            return response.get("status") == "ok"
        except AIServiceException:
            return False

    def chat(
        self,
        message: str,
        session_id: str,
        history: Optional[List[Dict]] = None
    ) -> Dict:
        """
        Envía mensaje a chat conversacional de IA.
        Mantiene contexto de conversación anterior.

        Args:
            message: Mensaje del usuario
            session_id: ID único de sesión (ej: "user-123")
            history: Historial anterior de chat

        Returns:
            dict: {
                "reply": "Respuesta de IA",
                "session_id": "user-123",
                "model_used": "gemini" | "rule-based"
            }
        """
        if not message or not message.strip():
            raise ValueError("El mensaje no puede estar vacío")

        payload = {
            "message": message.strip(),
            "session_id": session_id,
            "history": history or []
        }

        return self._request("POST", "/chat", payload)

    def enhance_artwork(
        self,
        artwork_id: str,
        title: str,
        technique: str = "",
        material: str = "",
        description: str = "",
        dimensions: str = "",
        regenerate_description: bool = False
    ) -> Dict:
        """
        Enriquece metadata de obra de arte con etiquetas y descripción IA.

        Args:
            artwork_id: ID único de la obra
            title: Título de la obra
            technique: Técnica (óleo, acuarela, etc.)
            material: Material (tela, papel, etc.)
            description: Descripción actual
            dimensions: Dimensiones (ej: "100x80cm")
            regenerate_description: Si regenerar descripción

        Returns:
            dict: {
                "tags": ["tag1", "tag2", ...],
                "ai_description": "Descripción mejorada"
            }
        """
        payload = {
            "artwork_id": artwork_id,
            "title": title,
            "technique": technique,
            "material": material,
            "description": description,
            "dimensions": dimensions,
            "regenerate_description": regenerate_description
        }

        return self._request("POST", "/artworks/enhance", payload)

    def recommend_music(self, query: str) -> Dict:
        """
        Obtiene recomendaciones de música basadas en búsqueda natural.
        Extrae filtros (género, ciudad, tipo agregación) de consulta.

        Args:
            query: Búsqueda en lenguaje natural
                  (ej: "bandas de rock en Pasto")

        Returns:
            dict: {
                "genres": ["Rock"],
                "city": "Pasto",
                "region": "Nariño",
                "aggregation_type": "BANDA",
                "keywords": [...]
            }
        """
        if not query or not query.strip():
            raise ValueError("La búsqueda no puede estar vacía")

        payload = {"query": query.strip()}

        return self._request("POST", "/music/recommendations", payload)


class AIServiceException(Exception):
    """Excepción para errores del servicio de IA."""
    pass
