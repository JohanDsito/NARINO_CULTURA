from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

import requests
from django.conf import settings

from apps.events.models import Event


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
        return Event.objects.create(organizer=organizer, **validated_data)

    @staticmethod
    def extract_from_flyer(*, organizer, image_url: str = "", flyer_text: str = "") -> dict[str, Any]:
        base_url = getattr(settings, "AI_SERVICE_URL", "").rstrip("/")
        if base_url:
            payload = {"image_url": image_url, "flyer_text": flyer_text}
            try:
                response = requests.post(
                    f"{base_url}/events/extract-from-flyer",
                    json=payload,
                    timeout=20,
                )
                response.raise_for_status()
                data = response.json() if response.content else {}
                data.setdefault("source", "ai_service")
                data.setdefault("image_url", image_url)
                data.setdefault("raw_text", flyer_text)
                data["is_published"] = False if getattr(organizer, "role", None) == "ARTISTA" else bool(data.get("is_published", False))
                return data
            except requests.RequestException:
                pass

        data = EventService._heuristic_extract(image_url=image_url, flyer_text=flyer_text)
        data["source"] = "heuristic"
        data["is_published"] = False if getattr(organizer, "role", None) == "ARTISTA" else False
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

        candidate = datetime(year, month, day, hour, minute, tzinfo=ZoneInfo(getattr(settings, "TIME_ZONE", "America/Bogota")))
        if candidate < now and not date_match.group(3):
            candidate = candidate.replace(year=year + 1)
        return candidate

    @staticmethod
    def _infer_event_type(text: str) -> str:
        normalized = text.lower()
        for event_type, keywords in EventService.EVENT_TYPE_KEYWORDS.items():
            if any(keyword in normalized for keyword in keywords):
                return event_type
        return Event.Type.OTRO
