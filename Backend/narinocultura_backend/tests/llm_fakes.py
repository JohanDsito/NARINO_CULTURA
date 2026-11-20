"""Respuestas falsas de Gemini y Groq para los tests (nunca se llama a la red)."""
import json
from unittest.mock import MagicMock

import requests

KEYS = {"GEMINI_API_KEY": "gemini-test", "GROQ_API_KEY": "groq-test"}


def gemini(payload) -> MagicMock:
    text = payload if isinstance(payload, str) else json.dumps(payload)
    return _response({"candidates": [{"content": {"parts": [{"text": text}]}}]})


def groq(payload) -> MagicMock:
    text = payload if isinstance(payload, str) else json.dumps(payload)
    return _response({"choices": [{"message": {"content": text}}]})


def http_error(status: int) -> MagicMock:
    response = MagicMock(status_code=status)
    response.raise_for_status.side_effect = requests.HTTPError(response=response)
    return response


def _response(body: dict) -> MagicMock:
    response = MagicMock(status_code=200)
    response.raise_for_status.return_value = None
    response.json.return_value = body
    return response
