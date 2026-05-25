from __future__ import annotations

import requests
from django.conf import settings

from apps.artworks.models import Artwork


class AIService:
    @staticmethod
    def enhance_artwork(artwork: Artwork, regenerate_description: bool = False) -> dict:
        base_url = getattr(settings, "AI_SERVICE_URL", "")
        if not base_url:
            raise RuntimeError("Servicio de IA no configurado.")

        payload = {
            "artwork_id": str(artwork.id),
            "title": artwork.title,
            "description": artwork.description,
            "technique": artwork.technique,
            "dimensions": artwork.dimensions,
            "material": artwork.material,
            "regenerate_description": regenerate_description,
        }
        try:
            response = requests.post(f"{base_url.rstrip('/')}/artworks/enhance", json=payload, timeout=15)
            response.raise_for_status()
        except requests.RequestException:
            raise RuntimeError("No fue posible contactar el microservicio de IA.")

        data = response.json() if response.content else {}
        artwork.ai_tags = data.get("tags", artwork.ai_tags)
        artwork.ai_description = data.get("ai_description", artwork.ai_description)
        artwork.save(update_fields=["ai_tags", "ai_description", "updated_at"])
        return {"ai_tags": artwork.ai_tags, "ai_description": artwork.ai_description}

