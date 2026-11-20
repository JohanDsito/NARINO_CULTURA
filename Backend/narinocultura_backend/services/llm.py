"""Acceso a modelos de lenguaje por HTTPS: Gemini (principal) y Groq (respaldo).

Se llama a las API REST con ``requests`` en lugar de los SDK para no sumar dependencias
ni memoria al proceso web. Cada proveedor configurado se prueba en orden; si ninguno
responde (sin llave, cuota agotada con 429, caída o respuesta inválida) se lanza
``LLMUnavailableError`` y quien llama usa sus reglas locales. Las dos llaves de capa gratuita
no generan cobros: al agotar la cuota del día la API solo responde 429.
"""
from __future__ import annotations

import base64
import json
import logging
import re
from collections.abc import Callable, Iterable
from dataclasses import dataclass
from typing import Any

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"


class LLMUnavailableError(Exception):
    """Ningún proveedor de IA respondió; se debe usar el respaldo por reglas."""


@dataclass(frozen=True)
class Image:
    mime_type: str
    data: bytes


@dataclass(frozen=True)
class LLMResult:
    text: str
    provider: str
    data: dict | None = None


def is_configured() -> bool:
    return bool(settings.GEMINI_API_KEY or settings.GROQ_API_KEY)


def generate(
    prompt: str,
    *,
    system: str = "",
    history: Iterable[dict] = (),
    json_output: bool = False,
    image: Image | None = None,
    max_tokens: int = 600,
) -> LLMResult:
    """Devuelve la primera respuesta válida. ``history`` son turnos {"role": "user"|"model", "text"}.

    Con ``json_output`` la respuesta debe ser un objeto JSON (queda en ``LLMResult.data``);
    si un proveedor devuelve otra cosa se pasa al siguiente.
    """
    history = list(history)
    for name, call in _providers(needs_vision=image is not None):
        try:
            text = call(prompt, system=system, history=history, json_output=json_output, image=image, max_tokens=max_tokens)
        except (requests.RequestException, ValueError, KeyError, IndexError, TypeError) as exc:
            logger.warning("Proveedor de IA %s no respondió: %s", name, _describe(exc))
            continue
        text = (text or "").strip()
        if not text:
            logger.warning("Proveedor de IA %s devolvió una respuesta vacía", name)
            continue
        if not json_output:
            return LLMResult(text=text, provider=name)
        data = parse_json_object(text)
        if data is not None:
            return LLMResult(text=text, provider=name, data=data)
        logger.warning("Proveedor de IA %s no devolvió JSON válido", name)
    raise LLMUnavailableError("Ningún proveedor de IA disponible.")


def parse_json_object(text: str) -> dict | None:
    """Extrae un objeto JSON aunque venga envuelto en ```json ... ``` o con texto alrededor."""
    candidates = [text]
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        candidates.append(match.group())
    for candidate in candidates:
        try:
            data = json.loads(candidate)
        except ValueError:
            continue
        if isinstance(data, dict):
            return data
    return None


def _providers(*, needs_vision: bool) -> list[tuple[str, Callable[..., str]]]:
    providers = []
    if settings.GEMINI_API_KEY:
        providers.append(("gemini", _call_gemini))
    # Los modelos de texto de Groq no leen imágenes: el afiche solo se analiza con Gemini
    if settings.GROQ_API_KEY and not needs_vision:
        providers.append(("groq", _call_groq))
    return providers


def _call_gemini(prompt, *, system, history, json_output, image, max_tokens) -> str:
    parts: list[dict[str, Any]] = [{"text": prompt}]
    if image is not None:
        parts.append({"inline_data": {"mime_type": image.mime_type, "data": base64.b64encode(image.data).decode()}})
    contents = [{"role": turn["role"], "parts": [{"text": turn["text"]}]} for turn in history]
    contents.append({"role": "user", "parts": parts})

    body: dict[str, Any] = {
        "contents": contents,
        "generationConfig": {"maxOutputTokens": max_tokens, "temperature": 0.4},
    }
    if system:
        body["systemInstruction"] = {"parts": [{"text": system}]}
    if json_output:
        body["generationConfig"]["responseMimeType"] = "application/json"

    response = requests.post(
        GEMINI_URL.format(model=settings.GEMINI_MODEL),
        headers={"x-goog-api-key": settings.GEMINI_API_KEY},
        json=body,
        timeout=settings.AI_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    candidate = response.json()["candidates"][0]
    return "".join(part.get("text", "") for part in candidate["content"]["parts"])


def _call_groq(prompt, *, system, history, json_output, image, max_tokens) -> str:
    messages = [{"role": "system", "content": system}] if system else []
    messages += [
        {"role": "assistant" if turn["role"] == "model" else "user", "content": turn["text"]} for turn in history
    ]
    messages.append({"role": "user", "content": prompt})

    body: dict[str, Any] = {
        "model": settings.GROQ_MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0.4,
    }
    if json_output:
        body["response_format"] = {"type": "json_object"}

    response = requests.post(
        GROQ_URL,
        headers={"Authorization": f"Bearer {settings.GROQ_API_KEY}"},
        json=body,
        timeout=settings.AI_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"]


def _describe(exc: Exception) -> str:
    # Nunca se registra la URL completa ni los encabezados: llevarían la llave
    response = getattr(exc, "response", None)
    if response is not None:
        return f"HTTP {response.status_code}"
    return exc.__class__.__name__
