from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import Any
from urllib.parse import urljoin, urlparse
from uuid import uuid4
from zoneinfo import ZoneInfo

from django.conf import settings
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage

from apps.events.models import Event
from services import llm
from services.ai_service import AIService
from utils.media import IMAGE_EXTENSIONS


class EventService:
    MONTHS = {
        "enero": 1,
        "febrero": 2,
        "marzo": 3,
        "abril": 4,
        "mayo": 5,
        "junio": 6,
        "julio": 7,
        "agosto": 8,
        "septiembre": 9,
        "setiembre": 9,
        "octubre": 10,
        "noviembre": 11,
        "diciembre": 12,
    }

    EVENT_TYPE_KEYWORDS = {
        "CONCIERTO": ("concierto", "show", "presentacion", "gira", "recital", "musica en vivo"),
        "EXPOSICION": ("exposicion", "muestra", "galeria", "museo"),
        "TALLER": ("taller", "workshop", "clase", "masterclass"),
        "FERIA": ("feria", "mercado", "festival de emprendimiento"),
        "ESPECTACULO": ("espectaculo", "obra", "teatro", "performance", "danza"),
    }

    @staticmethod
    def create_event(*, organizer, validated_data: dict[str, Any]) -> Event:
        if getattr(organizer, "role", None) == "ARTISTA":
            validated_data["is_published"] = False
        flyer = validated_data.pop("flyer", None)
        if flyer is not None:
            validated_data["image_url"] = EventService.store_flyer(flyer)
        return Event.objects.create(organizer=organizer, **validated_data)

    @staticmethod
    def store_flyer(image: llm.Image) -> str:
        """Guarda el afiche subido (Cloudinary en producción) y devuelve su URL absoluta."""
        name = default_storage.save(f"events/flyers/{uuid4().hex}{IMAGE_EXTENSIONS[image.mime_type]}", ContentFile(image.data))
        url = default_storage.url(name)
        return url if urlparse(url).scheme else urljoin(settings.API_BASE_URL, url)

    @staticmethod
    def extract_from_flyer(
        *, organizer, image_url: str = "", flyer_text: str = "", flyer: llm.Image | None = None
    ) -> dict[str, Any]:
        """Propone los datos de un evento a partir del afiche (URL, archivo subido y/o texto).
        Con IA disponible se lee la imagen y el texto; lo que la IA no encuentre (o todo, si no hay
        IA) se completa con la heurística. Un archivo subido se guarda y su URL queda en image_url,
        para que el formulario o el borrador lo usen. La sugerencia nunca sale publicada."""
        if flyer is not None:
            image_url = EventService.store_flyer(flyer)
        data = EventService._heuristic_extract(image_url=image_url, flyer_text=flyer_text)
        data["source"] = "heuristic"

        suggestion = AIService.extract_event_from_flyer(image_url=image_url, flyer_text=flyer_text, image=flyer)
        if suggestion:
            data["source"] = "ai_service"
            data["model_used"] = suggestion.pop("model_used")
            if suggestion.get("event_type") == Event.Type.OTRO:
                suggestion.pop("event_type")
            if not suggestion.get("start_date"):
                suggestion.pop("start_date", None)
                suggestion.pop("end_date", None)
            data.update({key: value for key, value in suggestion.items() if value})

        data["is_published"] = False
        return data

    @staticmethod
    def create_draft_from_extraction(*, organizer, extracted_data: dict[str, Any]) -> Event:
        if not extracted_data.get("start_date") or not extracted_data.get("end_date"):
            raise ValueError(
                "No fue posible identificar fecha y hora suficientes en el flyer para crear el borrador."
            )

        allowed_fields = {
            "title",
            "description",
            "event_type",
            "start_date",
            "end_date",
            "location",
            "image_url",
            "is_published",
        }
        payload = {key: value for key, value in extracted_data.items() if key in allowed_fields}
        payload["is_published"] = False if getattr(organizer, "role", None) == "ARTISTA" else bool(payload.get("is_published", False))
        return Event.objects.create(organizer=organizer, **payload)

    @staticmethod
    def _heuristic_extract(*, image_url: str, flyer_text: str) -> dict[str, Any]:
        text = (flyer_text or "").strip()
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        title = lines[0] if lines else "Evento cultural"
        description = text
        location = EventService._extract_location(text)
        start_date = EventService._extract_start_date(text)
        end_date = start_date + timedelta(hours=2) if start_date else None
        event_type = EventService._infer_event_type(text or title)

        return {
            "title": title,
            "description": description,
            "event_type": event_type,
            "start_date": start_date,
            "end_date": end_date,
            "location": location,
            "image_url": image_url or "",
            "raw_text": text,
        }

    @staticmethod
    def _extract_location(text: str) -> str:
        if not text:
            return ""
        match = re.search(
            r"(?:en|lugar|ubicacion|ubicación)\s*[:\-]?\s*([A-Za-z0-9ÁÉÍÓÚáéíóúÑñ ,.]+)",
            text,
            flags=re.IGNORECASE,
        )
        return match.group(1).strip(" .,-") if match else ""

    @staticmethod
    def _extract_start_date(text: str) -> datetime | None:
        if not text:
            return None

        date_match = re.search(
            r"(\d{1,2})\s+de\s+([a-zA-Záéíóúñ]+)(?:\s+de\s+(\d{4}))?",
            text,
            flags=re.IGNORECASE,
        )
        time_match = re.search(
            r"(\d{1,2})(?::(\d{2}))?\s*(a\.?\s*m\.?|p\.?\s*m\.?|am|pm)",
            text,
            flags=re.IGNORECASE,
        )

        if not date_match:
            return None

        day = int(date_match.group(1))
        month_name = date_match.group(2).lower()
        month = EventService.MONTHS.get(month_name)
        if not month:
            return None

        now = datetime.now(ZoneInfo(getattr(settings, "TIME_ZONE", "America/Bogota")))
        year = int(date_match.group(3)) if date_match.group(3) else now.year

        hour = 19
        minute = 0
        if time_match:
            hour = int(time_match.group(1))
            minute = int(time_match.group(2) or 0)
            meridiem = time_match.group(3).replace(".", "").replace(" ", "").lower()
            if meridiem == "pm" and hour < 12:
                hour += 12
            if meridiem == "am" and hour == 12:
                hour = 0

        try:
            candidate = datetime(year, month, day, hour, minute, tzinfo=ZoneInfo(getattr(settings, "TIME_ZONE", "America/Bogota")))
            if candidate < now and not date_match.group(3):
                candidate = candidate.replace(year=year + 1)
        except ValueError:
            # Fecha u hora imposible en el flyer ("31 de febrero", "30 pm", 29 de febrero del año siguiente):
            # se deja sin fecha para que el organizador la escriba, en vez de responder 500.
            return None
        return candidate

    @staticmethod
    def _infer_event_type(text: str) -> str:
        normalized = text.lower()
        for event_type, keywords in EventService.EVENT_TYPE_KEYWORDS.items():
            if any(keyword in normalized for keyword in keywords):
                return event_type
        return Event.Type.OTRO
