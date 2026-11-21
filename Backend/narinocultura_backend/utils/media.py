def artwork_image_url(artwork, request=None) -> str:
    """URL absoluta de la imagen principal de una obra (archivo subido o URL externa)."""
    if artwork.main_image:
        url = artwork.main_image.url
        return request.build_absolute_uri(url) if request else url
    return artwork.main_image_url or ""


def public_name(user) -> str:
    """Nombre visible para otros usuarios: nombre e inicial del apellido ("Ana P.")."""
    initial = f" {user.last_name[:1]}." if user.last_name else ""
    return f"{user.first_name}{initial}".strip() or "Postor"


IMAGE_EXTENSIONS = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp", "image/heic": ".heic"}


def sniff_image_type(data: bytes) -> str | None:
    """Tipo real de la imagen según sus primeros bytes (no se confía en la extensión ni en el
    Content-Type que envía el cliente). Solo los formatos que Gemini acepta."""
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    if data[4:8] == b"ftyp" and data[8:12] in (b"heic", b"heix", b"hevc", b"mif1", b"msf1"):
        return "image/heic"
    return None
