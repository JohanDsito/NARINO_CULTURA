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
