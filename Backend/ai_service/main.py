"""
Nariño Cultura AI Microservice
Provides AI-powered artwork enhancement: tagging and description generation.
"""
from __future__ import annotations

import os
from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(
    title="Nariño Cultura AI Service",
    description="Microservicio de inteligencia artificial para enriquecimiento de obras de arte",
    version="1.0.0",
)

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class ArtworkEnhanceRequest(BaseModel):
    artwork_id: str
    title: str
    description: str = ""
    technique: str = ""
    dimensions: str = ""
    material: str = ""
    regenerate_description: bool = False


class ArtworkEnhanceResponse(BaseModel):
    tags: list[str]
    ai_description: str


class EventExtractionRequest(BaseModel):
    image_url: str
    raw_text: Optional[str] = None


class MusicRecommendationRequest(BaseModel):
    query: str


class MusicRecommendationFilters(BaseModel):
    genres: list[str] = []
    city: str = ""
    region: str = ""
    aggregation_type: str = ""
    keywords: list[str] = []


class EventExtractionResponse(BaseModel):
    title: str = ""
    description: str = ""
    event_type: str = "OTRO"
    location: str = ""
    suggested_tags: list[str] = []


# ---------------------------------------------------------------------------
# Tag generation helpers (rule-based, no external API required)
# ---------------------------------------------------------------------------

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
    "papel": ["papel", "gráfico", "delicado"],
    "barro": ["barro", "artesanía", "nariño"],
    "arcilla": ["arcilla", "cerámica", "moldeado"],
    "vidrio": ["vidrio", "transparencia", "luz"],
    "bronce": ["bronce", "escultura", "patrimonio"],
    "mármol": ["mármol", "escultura", "clásico"],
    "marmol": ["mármol", "escultura", "clásico"],
}

LANDSCAPE_KEYWORDS = ["paisaje", "montaña", "río", "lago", "bosque", "campo", "naturaleza", "andino", "andes",
                      "nariño", "pasto", "volcan", "volcán", "llanura", "cielo", "mar"]
FIGURE_KEYWORDS = ["retrato", "figura", "persona", "mujer", "hombre", "niño", "cara", "rostro", "humano", "familia"]
ABSTRACT_KEYWORDS = ["abstracto", "forma", "color", "geometría", "geometria", "linea", "línea", "expresión",
                     "emoción", "concepto", "idea"]
CULTURAL_KEYWORDS = ["cultura", "tradición", "tradicion", "indígena", "indigena", "colombia", "nariño",
                     "ancestral", "folclor", "folclore", "carnaval", "folklore"]


def _keywords_in_text(text: str, keywords: list[str]) -> bool:
    text_lower = text.lower()
    return any(kw in text_lower for kw in keywords)


def generate_tags(request: ArtworkEnhanceRequest) -> list[str]:
    tags: set[str] = set()
    combined_text = f"{request.title} {request.description}".lower()

    # Add tags from technique
    for key, technique_tags in TECHNIQUE_TAGS.items():
        if key in request.technique.lower():
            tags.update(technique_tags)

    # Add tags from material
    for key, material_tags in MATERIAL_TAGS.items():
        if key in request.material.lower():
            tags.update(material_tags)

    # Add semantic tags from title + description
    if _keywords_in_text(combined_text, LANDSCAPE_KEYWORDS):
        tags.update(["paisaje", "naturaleza", "colombia"])
    if _keywords_in_text(combined_text, FIGURE_KEYWORDS):
        tags.update(["figura-humana", "retrato"])
    if _keywords_in_text(combined_text, ABSTRACT_KEYWORDS):
        tags.update(["abstracto", "arte-contemporáneo"])
    if _keywords_in_text(combined_text, CULTURAL_KEYWORDS):
        tags.update(["cultura-nariñense", "patrimonio-cultural", "colombia"])

    # Always include general tags
    tags.add("arte-colombiano")
    tags.add("nariño-cultura")

    return sorted(tags)[:10]  # Cap at 10 tags


def generate_description(request: ArtworkEnhanceRequest) -> str:
    parts = []

    if request.title:
        parts.append(f'"{request.title}" es una obra que captura la esencia del arte de la región Nariño, Colombia.')

    if request.technique:
        parts.append(f"Elaborada con la técnica de {request.technique.lower()},")

    if request.material:
        parts.append(f"utilizando {request.material.lower()} como medio de expresión.")

    if request.dimensions:
        parts.append(f"La obra tiene dimensiones de {request.dimensions}.")

    if request.description:
        parts.append(request.description)
    else:
        parts.append(
            "Esta pieza representa la riqueza cultural y artística de Nariño, "
            "fusionando técnicas tradicionales con una visión contemporánea."
        )

    return " ".join(parts)


# ---------------------------------------------------------------------------
# Optional: Google Gemini-powered enhancement (using new google-genai SDK)
# ---------------------------------------------------------------------------

async def _gemini_enhance(request: ArtworkEnhanceRequest) -> Optional[ArtworkEnhanceResponse]:
    gemini_key = os.getenv("GEMINI_API_KEY", "")
    if not gemini_key:
        return None
    try:
        from google import genai
        import json
        import re

        # Pasar explícitamente la API key
        client = genai.Client(api_key=gemini_key)

        prompt = (
            f"Eres un curador de arte colombiano especializado en arte de Nariño. "
            f"Para la obra titulada '{request.title}', con técnica '{request.technique}', "
            f"material '{request.material}' y descripción: '{request.description}', "
            f"genera: 1) Una lista de 5-8 etiquetas (tags) en español, separadas por coma. "
            f"2) Una descripción artística de 2-3 oraciones. "
            f"Responde EXACTAMENTE en formato JSON (sin markdown): {{\"tags\": [...], \"description\": \"...\"}}"
        )

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
        )

        # Extract JSON from response
        text = response.text
        json_match = re.search(r'\{.*\}', text, re.DOTALL)
        if not json_match:
            return None

        data = json.loads(json_match.group())
        tags = data.get("tags", [])
        if isinstance(tags, str):
            tags = [t.strip() for t in tags.split(",")]

        return ArtworkEnhanceResponse(
            tags=tags,
            ai_description=data.get("description", ""),
        )
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Optional: OpenAI-powered enhancement
# ---------------------------------------------------------------------------

async def _openai_enhance(request: ArtworkEnhanceRequest) -> Optional[ArtworkEnhanceResponse]:
    openai_key = os.getenv("OPENAI_API_KEY", "")
    if not openai_key:
        return None
    try:
        import openai
        client = openai.AsyncOpenAI(api_key=openai_key)
        prompt = (
            f"Eres un curador de arte colombiano especializado en arte de Nariño. "
            f"Para la obra titulada '{request.title}', con técnica '{request.technique}', "
            f"material '{request.material}' y descripción: '{request.description}', "
            f"genera: 1) Una lista de 5-8 etiquetas (tags) en español, separadas por coma. "
            f"2) Una descripción artística de 2-3 oraciones. "
            f"Responde en formato JSON: {{\"tags\": [...], \"description\": \"...\"}}"
        )
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            max_tokens=300,
        )
        import json
        data = json.loads(response.choices[0].message.content)
        return ArtworkEnhanceResponse(
            tags=data.get("tags", []),
            ai_description=data.get("description", ""),
        )
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@app.get("/health")
async def health():
    return {"status": "ok", "service": "narino-cultura-ai"}


# ---------------------------------------------------------------------------
# Chat conversacional con historial
# ---------------------------------------------------------------------------

class ChatMessage(BaseModel):
    role: str  # "user" o "model"
    text: str


class ChatRequest(BaseModel):
    message: str
    session_id: str = "default"
    history: list[ChatMessage] = []  # Historial anterior


class ChatResponse(BaseModel):
    reply: str
    session_id: str
    model_used: str  # "gemini" o "rule-based"


# Almacenar historial en memoria (en producción, usar base de datos)
_chat_sessions: dict = {}


@app.post("/chat", response_model=ChatResponse)
async def chat_conversational(request: ChatRequest):
    """
    Chat conversacional con Gemini o fallback Rule-Based.
    Mantiene historial de conversación para contexto.
    """
    session_id = request.session_id

    # Inicializar sesión si no existe
    if session_id not in _chat_sessions:
        _chat_sessions[session_id] = []

    # Agregar historial previo si viene en la petición
    if request.history:
        _chat_sessions[session_id] = [
            {"role": msg.role, "text": msg.text} for msg in request.history
        ]

    model_used = "rule-based"

    # Try Gemini first
    gemini_key = os.getenv("GEMINI_API_KEY", "")
    if gemini_key:
        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=gemini_key)

            # Convertir historial al formato de Gemini
            formatted_history = []
            for msg in _chat_sessions[session_id]:
                formatted_history.append(
                    types.Content(
                        role=msg['role'],
                        parts=[types.Part.from_text(text=msg['text'])]
                    )
                )

            # Crear chat con historial
            chat = client.chats.create(
                model="gemini-2.0-flash",
                history=formatted_history,
                config=types.GenerateContentConfig(
                    system_instruction=(
                        "Eres un asistente experto en arte y música de Nariño, Colombia. "
                        "Ayudas a descubrir artistas, obras de arte y eventos culturales. "
                        "Responde siempre en español y de forma amigable."
                    )
                )
            )

            # Enviar nuevo mensaje
            response = chat.send_message(request.message)
            bot_reply = response.text
            model_used = "gemini"

            # Guardar en historial
            _chat_sessions[session_id].append({"role": "user", "text": request.message})
            _chat_sessions[session_id].append({"role": "model", "text": bot_reply})

            return ChatResponse(
                reply=bot_reply,
                session_id=session_id,
                model_used=model_used
            )
        except Exception as e:
            # Fallback a Rule-Based si Gemini falla
            pass

    # Rule-Based fallback
    bot_reply = _generate_chat_response(request.message, _chat_sessions[session_id])

    # Guardar en historial
    _chat_sessions[session_id].append({"role": "user", "text": request.message})
    _chat_sessions[session_id].append({"role": "model", "text": bot_reply})

    return ChatResponse(
        reply=bot_reply,
        session_id=session_id,
        model_used=model_used
    )


def _generate_chat_response(user_message: str, history: list) -> str:
    """
    Genera respuesta basada en reglas cuando Gemini no está disponible.
    """
    msg_lower = user_message.lower()

    # Detección de intención
    if any(word in msg_lower for word in ["hola", "hi", "buenos", "buenos días"]):
        return (
            "¡Hola! Bienvenido a Nariño Cultura. "
            "Soy tu asistente de arte y música. ¿Qué tipo de obras o artistas te interesan?"
        )

    if any(word in msg_lower for word in ["artista", "músico", "pintor", "escultor"]):
        return (
            "En nuestra plataforma puedes encontrar artistas de todas las disciplinas de Nariño. "
            "¿Te interesan artistas de un género específico como rock, salsa, música andina, o artes visuales?"
        )

    if any(word in msg_lower for word in ["obra", "cuadro", "pintura", "escultura", "arte"]):
        return (
            "Tenemos una amplia colección de obras de arte. "
            "¿Buscas una técnica específica (óleo, acuarela, fotografía) o un tema en particular?"
        )

    if any(word in msg_lower for word in ["evento", "concierto", "exposición", "taller", "festival"]):
        return (
            "¡Excelente! En Nariño hay muchos eventos culturales. "
            "¿Te gustaría saber sobre conciertos, exposiciones, talleres u otros tipos de eventos?"
        )

    if any(word in msg_lower for word in ["precio", "costo", "comprar", "orden"]):
        return (
            "Puedes comprar obras directamente a través de nuestro marketplace. "
            "¿Hay alguna obra específica que te haya llamado la atención?"
        )

    if any(word in msg_lower for word in ["gracias", "thanks", "ok", "listo", "perfecto"]):
        return "¡De nada! Si necesitas algo más, estoy aquí para ayudarte. 😊"

    # Default
    return (
        "Entiendo tu pregunta. "
        "Puedo ayudarte a buscar artistas, obras, eventos culturales y más. "
        "¿Qué específicamente te interesa explorar?"
    )


@app.post("/artworks/enhance", response_model=ArtworkEnhanceResponse)
async def enhance_artwork(request: ArtworkEnhanceRequest):
    # Try Gemini first if configured (GRATIS & potente)
    gemini_result = await _gemini_enhance(request)
    if gemini_result:
        return gemini_result

    # Try OpenAI as fallback
    openai_result = await _openai_enhance(request)
    if openai_result:
        return openai_result

    # Fallback to rule-based generation (GRATIS, siempre funciona)
    tags = generate_tags(request)
    description = (
        generate_description(request)
        if request.regenerate_description or not request.description
        else request.description
    )
    return ArtworkEnhanceResponse(tags=tags, ai_description=description)


MUSIC_GENRE_KEYWORDS: dict[str, str] = {
    "rock": "Rock",
    "metal": "Metal",
    "pop": "Pop",
    "salsa": "Salsa",
    "cumbia": "Cumbia",
    "vallenato": "Vallenato",
    "hip hop": "Hip Hop",
    "rap": "Rap",
    "jazz": "Jazz",
    "blues": "Blues",
    "electrónica": "Electrónica",
    "electronica": "Electrónica",
    "reggaeton": "Reggaetón",
    "reggae": "Reggae",
    "andina": "Música Andina",
    "andino": "Música Andina",
    "folklor": "Folclore",
    "folclore": "Folclore",
    "indie": "Indie",
    "alternativo": "Rock Alternativo",
    "chirimia": "Chirimía",
    "chirimía": "Chirimía",
    "bambuco": "Bambuco",
    "pasillo": "Pasillo",
    "marimba": "Marimba",
    "cumbia nariñense": "Cumbia Nariñense",
    "tropical": "Tropical",
    "bolero": "Bolero",
}

MUSIC_CITY_KEYWORDS: dict[str, str] = {
    "pasto": "Pasto",
    "ipiales": "Ipiales",
    "tumaco": "Tumaco",
    "túquerres": "Túquerres",
    "tuperres": "Túquerres",
    "la unión": "La Unión",
}

MUSIC_AGGREGATION_KEYWORDS: dict[str, str] = {
    "banda": "BANDA",
    "band": "BANDA",
    "solista": "SOLISTA",
    "soloist": "SOLISTA",
    "dj": "DJ",
    "colectivo": "COLECTIVO",
    "dúo": "DUO",
    "duo": "DUO",
    "trío": "TRIO",
    "trio": "TRIO",
}


def _parse_music_query_locally(query: str) -> MusicRecommendationFilters:
    q = query.lower()

    genres: list[str] = []
    for kw, genre in MUSIC_GENRE_KEYWORDS.items():
        if kw in q and genre not in genres:
            genres.append(genre)

    city = ""
    region = ""
    for kw, city_name in MUSIC_CITY_KEYWORDS.items():
        if kw in q:
            city = city_name
            break
    if "nariño" in q or "narino" in q:
        region = "Nariño"

    aggregation_type = ""
    for kw, agg in MUSIC_AGGREGATION_KEYWORDS.items():
        if kw in q:
            aggregation_type = agg
            break

    return MusicRecommendationFilters(
        genres=genres,
        city=city,
        region=region,
        aggregation_type=aggregation_type,
    )


@app.post("/music/recommendations", response_model=MusicRecommendationFilters)
async def music_recommendations(request: MusicRecommendationRequest):
    """
    Parse a natural language music discovery query and return structured filters.
    Priority: Gemini (GRATIS) → OpenAI → Rule-based fallback
    """
    # Try Gemini first (GRATIS) - using new google-genai SDK
    gemini_key = os.getenv("GEMINI_API_KEY", "")
    if gemini_key:
        try:
            from google import genai
            import json
            import re

            # Pasar explícitamente la API key
            client = genai.Client(api_key=gemini_key)

            prompt = (
                f"Eres un asistente de descubrimiento musical de Nariño, Colombia. "
                f"Extrae de esta consulta los filtros de búsqueda musical: '{request.query}' "
                f"Responde EXACTAMENTE en JSON (sin markdown): "
                f"{{\"genres\": [...], \"city\": \"\", \"region\": \"\", \"aggregation_type\": \"\", \"keywords\": [...]}}"
            )

            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt,
            )
            text = response.text
            json_match = re.search(r'\{.*\}', text, re.DOTALL)
            if json_match:
                data = json.loads(json_match.group())
                return MusicRecommendationFilters(**data)
        except Exception:
            pass

    # Try OpenAI as fallback
    openai_key = os.getenv("OPENAI_API_KEY", "")
    if openai_key:
        try:
            import json
            import openai
            client = openai.AsyncOpenAI(api_key=openai_key)
            response = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "Eres un asistente de descubrimiento musical de Nariño, Colombia. "
                            "Extrae de la consulta del usuario los filtros de búsqueda musical. "
                            "Responde en JSON con: genres (lista de géneros musicales en español), "
                            "city (ciudad colombiana si se menciona), region (región si se menciona), "
                            "aggregation_type (SOLISTA|BANDA|DJ|COLECTIVO|DUO|TRIO si se menciona), "
                            "keywords (palabras clave adicionales)."
                        ),
                    },
                    {"role": "user", "content": request.query},
                ],
                response_format={"type": "json_object"},
                max_tokens=200,
            )
            data = json.loads(response.choices[0].message.content)
            return MusicRecommendationFilters(**data)
        except Exception:
            pass

    # Fallback to rule-based (siempre funciona, GRATIS)
    return _parse_music_query_locally(request.query)


@app.post("/events/extract-from-flyer", response_model=EventExtractionResponse)
async def extract_from_flyer(request: EventExtractionRequest):
    """
    Extract event info from a flyer image URL.
    Priority: Gemini Vision → OpenAI Vision → Empty
    """
    # Try Gemini Vision first (GRATIS)
    gemini_key = os.getenv("GOOGLE_API_KEY", "")
    if gemini_key:
        try:
            from google import genai
            import json

            client = genai.Client(api_key=gemini_key)
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[
                    {
                        "text": (
                            "Analiza este afiche de evento cultural. Extrae: "
                            "title, description, event_type (CONCIERTO/EXPOSICION/TALLER/FERIA/ESPECTACULO/OTRO), "
                            "location, suggested_tags. Responde EXACTAMENTE en JSON."
                        )
                    },
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": request.image_url,
                        }
                    },
                ],
            )
            data = json.loads(response.text)
            return EventExtractionResponse(**data)
        except Exception:
            pass

    # Try OpenAI as fallback
    openai_key = os.getenv("OPENAI_API_KEY", "")
    if openai_key:
        try:
            import openai
            import json
            client = openai.AsyncOpenAI(api_key=openai_key)
            response = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": (
                                    "Analiza este afiche de evento cultural. Extrae: "
                                    "title, description, event_type (CONCIERTO/EXPOSICION/TALLER/FERIA/ESPECTACULO/OTRO), "
                                    "location, suggested_tags. Responde en JSON."
                                ),
                            },
                            {"type": "image_url", "image_url": {"url": request.image_url}},
                        ],
                    }
                ],
                response_format={"type": "json_object"},
                max_tokens=400,
            )
            data = json.loads(response.choices[0].message.content)
            return EventExtractionResponse(**data)
        except Exception:
            pass

    return EventExtractionResponse()
