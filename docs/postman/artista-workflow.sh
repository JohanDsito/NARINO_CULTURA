#!/bin/bash

# ==========================================
# NARIÑO CULTURA - EJEMPLOS DE cURL
# Flujo de pruebas para rol ARTISTA
# ==========================================

# Configurar variables
BASE_URL="http://localhost:8000"
EMAIL="artista@narinocultura.uk"
PASSWORD="SecurePassword123!"

echo "🎨 Iniciando pruebas de API como ARTISTA..."
echo ""

# ==========================================
# 1. REGISTRO COMO ARTISTA
# ==========================================
echo "1️⃣ Registrando nuevo artista..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auth/register/" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'",
    "first_name": "Juan",
    "last_name": "Pérez",
    "role": "ARTISTA",
    "phone": "+57 310 1234567",
    "avatar_url": "https://example.com/avatar.jpg"
  }')

echo "Respuesta: $REGISTER_RESPONSE"
echo ""

# ==========================================
# 2. VERIFICAR EMAIL (MANUAL)
# ==========================================
echo "2️⃣ Verificación de email"
echo "⚠️  IMPORTANTE: Copia el token de verificación del email"
echo "   Busca en: logs del servidor o email recibido"
echo "   Luego ejecuta:"
echo ""
echo 'curl -X POST "$BASE_URL/api/v1/auth/verify-email/" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d "{\"token\": \"TOKEN_AQUI\"}"'
echo ""
echo "Presiona Enter después de verificar..."
read

# ==========================================
# 3. LOGIN
# ==========================================
echo "3️⃣ Login como artista..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auth/login/" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$EMAIL'",
    "password": "'$PASSWORD'"
  }')

echo "Respuesta: $LOGIN_RESPONSE"
echo ""

# Extraer tokens
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access":"[^"]*' | cut -d'"' -f4)
REFRESH_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"refresh":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Error: No se obtuvo el token de acceso"
  exit 1
fi

echo "✅ Tokens obtenidos:"
echo "   Access Token: ${ACCESS_TOKEN:0:20}..."
echo "   Refresh Token: ${REFRESH_TOKEN:0:20}..."
echo ""

# ==========================================
# 4. OBTENER PERFIL
# ==========================================
echo "4️⃣ Obteniendo mi perfil de usuario..."
curl -s -X GET "$BASE_URL/api/v1/users/me/" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.' | head -20

echo ""

# ==========================================
# 5. LISTAR CATEGORÍAS
# ==========================================
echo "5️⃣ Listando categorías de obras..."
CATEGORIES_RESPONSE=$(curl -s -X GET "$BASE_URL/api/v1/artworks/categories/" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "$CATEGORIES_RESPONSE" | jq '.results[0]' 2>/dev/null || echo "$CATEGORIES_RESPONSE" | jq '.[0]'
CATEGORY_ID=$(echo "$CATEGORIES_RESPONSE" | jq -r '.results[0].id // .[0].id' 2>/dev/null)
echo "   Category ID: $CATEGORY_ID"
echo ""

# ==========================================
# 6. CREAR PERFIL DE ARTISTA
# ==========================================
echo "6️⃣ Creando perfil de artista..."
ARTIST_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/artists/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "artistic_name": "Juan Pérez Artista",
    "bio": "Artista plástico especializado en pintura abstracta",
    "location": "Pasto, Nariño",
    "website": "https://juanperezart.com",
    "instagram": "@juanperezart",
    "facebook": "JuanPerezArtista",
    "profile_image": "https://example.com/profile.jpg",
    "banner_image": "https://example.com/banner.jpg"
  }')

echo "$ARTIST_RESPONSE" | jq '.'
ARTIST_ID=$(echo "$ARTIST_RESPONSE" | jq -r '.id')
echo "   Artist ID: $ARTIST_ID"
echo ""

# ==========================================
# 7. CREAR OBRA DE ARTE
# ==========================================
echo "7️⃣ Creando nueva obra de arte..."
ARTWORK_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/artworks/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "title": "Abstracción Nariñense",
    "description": "Obra de arte abstracta inspirada en la naturaleza de Nariño",
    "category_id": "'$CATEGORY_ID'",
    "technique": "Acrílico sobre lienzo",
    "dimensions": "80x100 cm",
    "year_created": 2024,
    "price": 2500000,
    "image_url": "https://example.com/artwork.jpg",
    "is_available": true
  }')

echo "$ARTWORK_RESPONSE" | jq '.'
ARTWORK_ID=$(echo "$ARTWORK_RESPONSE" | jq -r '.id')
echo "   Artwork ID: $ARTWORK_ID"
echo ""

# ==========================================
# 8. LISTAR MIS OBRAS
# ==========================================
echo "8️⃣ Listando mis obras de arte..."
curl -s -X GET "$BASE_URL/api/v1/artworks/?artist=$ARTIST_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.results[0] // .[0]'

echo ""

# ==========================================
# 9. CREAR SUBASTA
# ==========================================
echo "9️⃣ Creando nueva subasta..."
AUCTION_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auctions/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "artwork_id": "'$ARTWORK_ID'",
    "starting_price": 1000000,
    "reserve_price": 1500000,
    "start_date": "2026-05-20T10:00:00Z",
    "end_date": "2026-05-27T18:00:00Z",
    "description": "Subasta exclusiva de obra de arte nariñense"
  }')

echo "$AUCTION_RESPONSE" | jq '.'
AUCTION_ID=$(echo "$AUCTION_RESPONSE" | jq -r '.id')
echo "   Auction ID: $AUCTION_ID"
echo ""

# ==========================================
# 10. VER MIS VENTAS
# ==========================================
echo "🔟 Consultando mis ventas..."
curl -s -X GET "$BASE_URL/api/v1/marketplace/sales/" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq '.results // .'

echo ""

# ==========================================
# RESUMEN
# ==========================================
echo "✅ RESUMEN DE IDs GENERADOS:"
echo "   access_token: ${ACCESS_TOKEN:0:30}..."
echo "   refresh_token: ${REFRESH_TOKEN:0:30}..."
echo "   artist_id: $ARTIST_ID"
echo "   artwork_id: $ARTWORK_ID"
echo "   auction_id: $AUCTION_ID"
echo "   category_id: $CATEGORY_ID"
echo ""
echo "💾 Guarda estos IDs para próximas pruebas"
echo ""

# ==========================================
# EJEMPLOS ADICIONALES
# ==========================================
echo "📝 EJEMPLOS ADICIONALES DE cURL:"
echo ""
echo "🔄 Refrescar token:"
echo 'curl -X POST "'$BASE_URL'/api/v1/auth/token/refresh/" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d "{\"refresh\": \"'$REFRESH_TOKEN'\"}"'
echo ""

echo "🔐 Cambiar contraseña:"
echo 'curl -X PATCH "'$BASE_URL'/api/v1/users/me/password/" \'
echo '  -H "Content-Type: application/json" \'
echo '  -H "Authorization: Bearer '$ACCESS_TOKEN'" \'
echo '  -d "{\"current_password\": \"'$PASSWORD'\", \"new_password\": \"NewPassword456!\"}"'
echo ""

echo "❤️ Agregar a favoritos:"
echo 'curl -X POST "'$BASE_URL'/api/v1/marketplace/favorites/" \'
echo '  -H "Content-Type: application/json" \'
echo '  -H "Authorization: Bearer '$ACCESS_TOKEN'" \'
echo '  -d "{\"artwork_id\": \"'$ARTWORK_ID'\"}"'
echo ""

echo "🛒 Agregar al carrito:"
echo 'curl -X POST "'$BASE_URL'/api/v1/marketplace/cart/items/" \'
echo '  -H "Content-Type: application/json" \'
echo '  -H "Authorization: Bearer '$ACCESS_TOKEN'" \'
echo '  -d "{\"artwork_id\": \"'$ARTWORK_ID'\", \"quantity\": 1}"'
echo ""

echo "📊 Hacer una puja:"
echo 'curl -X POST "'$BASE_URL'/api/v1/auctions/'$AUCTION_ID'/bid/" \'
echo '  -H "Content-Type: application/json" \'
echo '  -H "Authorization: Bearer '$ACCESS_TOKEN'" \'
echo '  -d "{\"auction_id\": \"'$AUCTION_ID'\", \"amount\": 1200000}"'
echo ""

echo "✨ Proceso completado!"
