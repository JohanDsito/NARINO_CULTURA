import os


def artwork_image_path(instance, filename):
    """Generate upload path: artworks/<artist_id>/<artwork_id>/<filename>"""
    ext = filename.rsplit(".", 1)[-1].lower()
    base = filename.rsplit(".", 1)[0]
    safe_name = f"{base}.{ext}"
    artwork = getattr(instance, "artwork", instance)
    artist_id = str(artwork.artist_id)
    artwork_id = str(artwork.id)
    return os.path.join("artworks", artist_id, artwork_id, safe_name)
