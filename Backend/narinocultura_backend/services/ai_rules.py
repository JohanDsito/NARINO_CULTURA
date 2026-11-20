"""Respaldo por reglas de la IA: responde siempre, sin red ni llaves.

Se usa cuando no hay proveedor configurado o cuando Gemini y Groq no responden
(por ejemplo, al agotar la cuota gratuita del día).
"""
from __future__ import annotations

TECHNIQUE_TAGS: dict[str, list[str]] = {
    "óleo": ["óleo", "pintura", "arte-tradicional"],
    "oleo": ["óleo", "pintura", "arte-tradicional"],
    "acuarela": ["acuarela", "pintura", "transparencia"],
    "acrílico": ["acrílico", "pintura", "color-vivo"],
    "acrilico": ["acrílico", "pintura", "color-vivo"],
    "escultura": ["escultura", "arte-tridimensional", "volumen"],
    "fotografía": ["fotografía", "arte-visual", "imagen"],
    "fotografia": ["fotografía", "arte-visual", "imagen"],
    "grabado": ["grabado", "impresión", "arte-gráfico"],
    "cerámica": ["cerámica", "artesanía", "barro"],
    "ceramica": ["cerámica", "artesanía", "barro"],
    "textil": ["textil", "tejido", "artesanía"],
    "bordado": ["bordado", "textil", "artesanía-nariñense"],
    "barniz": ["barniz-de-pasto", "mopa-mopa", "artesanía-nariñense"],
    "mopa": ["barniz-de-pasto", "mopa-mopa", "artesanía-nariñense"],
    "digital": ["arte-digital", "tecnología", "contemporáneo"],
    "pastel": ["pastel", "suave", "delicado"],
    "carboncillo": ["carboncillo", "dibujo", "monocromático"],
    "lápiz": ["lápiz", "dibujo", "línea"],
    "lapiz": ["lápiz", "dibujo", "línea"],
    "collage": ["collage", "mixto", "composición"],
    "mural": ["mural", "arte-urbano", "gran-formato"],
}

MATERIAL_TAGS: dict[str, list[str]] = {
    "madera": ["madera", "orgánico", "tallado"],
    "piedra": ["piedra", "escultura", "mineral"],
    "metal": ["metal", "industrial", "contemporáneo"],
    "tela": ["tela", "lienzo", "textil"],
    "lienzo": ["lienzo", "pintura"],
    "papel": ["papel", "gráfico", "delicado"],
    "barro": ["barro", "artesanía", "nariño"],
    "arcilla": ["arcilla", "cerámica", "moldeado"],
    "vidrio": ["vidrio", "transparencia", "luz"],
    "bronce": ["bronce", "escultura", "patrimonio"],
    "mármol": ["mármol", "escultura", "clásico"],
    "marmol": ["mármol", "escultura", "clásico"],
}

SEMANTIC_TAGS: list[tuple[tuple[str, ...], list[str]]] = [
    (
        ("paisaje", "montaña", "río", "lago", "bosque", "campo", "naturaleza", "andino", "andes",
         "volcan", "volcán", "galeras", "cocha", "cielo", "mar"),
        ["paisaje", "naturaleza"],
    ),
    (
        ("retrato", "figura", "persona", "mujer", "hombre", "niño", "niña", "cara", "rostro", "familia"),
        ["figura-humana", "retrato"],
    ),
    (
        ("abstracto", "abstracta", "geometría", "geometria", "expresión", "emoción", "concepto"),
        ["abstracto", "arte-contemporáneo"],
    ),
    (
        ("cultura", "tradición", "tradicion", "indígena", "indigena", "ancestral", "folclor", "folclore",
         "carnaval", "negros y blancos", "pasto"),
        ["cultura-nariñense", "patrimonio-cultural"],
    ),
]


def artwork_tags(*, title: str, description: str, technique: str, material: str) -> list[str]:
    tags: set[str] = set()
    for key, values in TECHNIQUE_TAGS.items():
        if key in technique.lower():
            tags.update(values)
    for key, values in MATERIAL_TAGS.items():
        if key in material.lower():
            tags.update(values)
    text = f"{title} {description}".lower()
    for keywords, values in SEMANTIC_TAGS:
        if any(keyword in text for keyword in keywords):
            tags.update(values)
    tags.update({"arte-colombiano", "nariño"})
    return sorted(tags)[:10]


def artwork_description(*, title: str, description: str, technique: str, material: str, dimensions: str) -> str:
    parts = []
    if title:
        parts.append(f"«{title}» es una obra que recoge la riqueza del arte de Nariño, Colombia.")
    if technique and material:
        parts.append(f"Está elaborada con la técnica de {technique.lower()} sobre {material.lower()}.")
    elif technique:
        parts.append(f"Está elaborada con la técnica de {technique.lower()}.")
    elif material:
        parts.append(f"Está elaborada en {material.lower()}.")
    if dimensions:
        parts.append(f"Sus dimensiones son {dimensions}.")
    parts.append(
        description.strip()
        or "La pieza une la tradición artística de la región con una mirada contemporánea."
    )
    return " ".join(parts)


def chat_reply(message: str) -> str:
    text = message.lower()
    if any(word in text for word in ("hola", "buenas", "buenos días", "buenas tardes", "hi")):
        return (
            "¡Hola! Bienvenido a Nariño Cultura. Puedo ayudarte a encontrar obras, artistas, "
            "músicos y eventos de Nariño. ¿Qué te interesa?"
        )
    if any(word in text for word in ("músico", "musico", "banda", "música", "musica", "canción", "concierto")):
        return (
            "En la sección de Músicos encuentras solistas, bandas y colectivos de Nariño. "
            "Puedes buscar por género o ciudad, por ejemplo «bandas de rock en Pasto»."
        )
    if any(word in text for word in ("evento", "festival", "exposición", "exposicion", "taller", "carnaval")):
        return (
            "En la sección de Eventos están los próximos conciertos, exposiciones y talleres. "
            "Puedes inscribirte desde el detalle de cada evento."
        )
    if any(word in text for word in ("precio", "costo", "comprar", "pagar", "pago", "orden", "pedido")):
        return (
            "Puedes comprar obras desde el catálogo: agrégalas al carrito y paga en línea con Wompi. "
            "Tus pedidos quedan en «Mis compras»."
        )
    if any(word in text for word in ("subasta", "puja", "pujar")):
        return "En Subastas puedes pujar en tiempo real por obras de artistas nariñenses."
    if any(word in text for word in ("artista", "pintor", "escultor", "obra", "cuadro", "pintura", "escultura", "arte")):
        return (
            "En el catálogo encuentras obras de artistas de Nariño. Puedes filtrar por técnica "
            "o por rango de precio. ¿Buscas algo en particular?"
        )
    if any(word in text for word in ("gracias", "listo", "perfecto", "ok")):
        return "¡Con gusto! Si necesitas algo más, aquí estoy."
    return (
        "Puedo ayudarte a explorar obras, artistas, músicos, subastas y eventos de Nariño Cultura. "
        "¿Qué te gustaría encontrar?"
    )


GENRE_KEYWORDS: dict[str, str] = {
    "rock": "Rock", "metal": "Metal", "salsa": "Salsa", "cumbia": "Cumbia",
    "vallenato": "Vallenato", "pop": "Pop", "hip hop": "Hip Hop", "rap": "Rap",
    "jazz": "Jazz", "blues": "Blues", "electrónica": "Electrónica",
    "electronica": "Electrónica", "reggaeton": "Reggaetón", "reggae": "Reggae",
    "andina": "Música Andina", "andino": "Música Andina", "folklor": "Folclore",
    "folclore": "Folclore", "indie": "Indie", "alternativo": "Rock Alternativo",
    "chirimía": "Chirimía", "chirimia": "Chirimía", "bambuco": "Bambuco",
    "pasillo": "Pasillo", "marimba": "Marimba", "cumbia nariñense": "Cumbia Nariñense",
}

CITY_KEYWORDS: dict[str, str] = {
    "pasto": "Pasto", "ipiales": "Ipiales", "tumaco": "Tumaco",
    "túquerres": "Túquerres", "tuquerres": "Túquerres", "la unión": "La Unión",
}

AGGREGATION_KEYWORDS: dict[str, str] = {
    "banda": "BANDA", "solista": "SOLISTA", "dj": "DJ",
    "colectivo": "COLECTIVO", "dúo": "DUO", "duo": "DUO",
    "trío": "TRIO", "trio": "TRIO",
}


def music_filters(query: str) -> dict:
    text = query.lower()
    filters: dict = {}
    genres = []
    for keyword, genre in GENRE_KEYWORDS.items():
        if keyword in text and genre not in genres:
            genres.append(genre)
    if genres:
        filters["genres"] = genres
    for keyword, city in CITY_KEYWORDS.items():
        if keyword in text:
            filters["city"] = city
            break
    else:
        if "nariño" in text or "narino" in text:
            filters["region"] = "Nariño"
    for keyword, aggregation in AGGREGATION_KEYWORDS.items():
        if keyword in text:
            filters["aggregation_type"] = aggregation
            break
    return filters
