import hashlib

from django.conf import settings

DEFAULT_PROPERTIES = ["transaction.id", "transaction.status", "transaction.amount_in_cents"]


def signed_wompi_event(transaction: dict, *, event="transaction.updated", timestamp=1530291411, secret=None) -> dict:
    """Arma un evento de Wompi firmado como lo documenta la pasarela:
    SHA-256 de los valores de `signature.properties` + `timestamp` + secreto de eventos."""
    secret = settings.WOMPI_EVENTS_SECRET if secret is None else secret
    raw = "".join(str(transaction[p.split(".", 1)[1]]) for p in DEFAULT_PROPERTIES) + str(timestamp) + secret
    return {
        "event": event,
        "data": {"transaction": transaction},
        "environment": "test",
        "signature": {
            "properties": DEFAULT_PROPERTIES,
            "checksum": hashlib.sha256(raw.encode("utf-8")).hexdigest().upper(),
        },
        "timestamp": timestamp,
        "sent_at": "2026-11-03T15:00:00.000Z",
    }
