# 📋 Referencia Rápida de URLs - Nariño Cultura API

**URL Base:** `http://localhost:8000/api/v1`

## 🔐 Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/auth/register/` | Registrar nuevo usuario (rol ARTISTA) |
| `POST` | `/auth/verify-email/` | Verificar email con token |
| `POST` | `/auth/login/` | Iniciar sesión |
| `POST` | `/auth/token/refresh/` | Refrescar token de acceso |
| `POST` | `/auth/logout/` | Cerrar sesión |
| `POST` | `/auth/password-reset/` | Solicitar reset de contraseña |
| `POST` | `/auth/password-reset/confirm/` | Confirmar cambio de contraseña |

## 👤 Usuario

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/users/me/` | Obtener perfil del usuario actual |
| `PATCH` | `/users/me/` | Actualizar perfil del usuario |
| `PATCH` | `/users/me/password/` | Cambiar contraseña |

## 🎨 Artistas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/artists/` | Listar todos los artistas (paginado) |
| `GET` | `/artists/{id}/` | Obtener detalle de un artista |
| `POST` | `/artists/` | Crear/actualizar perfil de artista |
| `GET` | `/artists/my-profile/` | Obtener mi perfil de artista |
| `PATCH` | `/artists/{id}/` | Actualizar perfil de artista |

## 🖼️ Obras de Arte

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/artworks/` | Listar obras (con filtros) |
| `POST` | `/artworks/` | Crear nueva obra |
| `GET` | `/artworks/{id}/` | Obtener detalle de obra |
| `PATCH` | `/artworks/{id}/` | Actualizar obra |
| `DELETE` | `/artworks/{id}/` | Eliminar obra |
| `GET` | `/artworks/categories/` | Listar categorías |

### Filtros disponibles para listar obras:
```
GET /artworks/?artist={artist_id}
GET /artworks/?category={category_id}
GET /artworks/?search={término}
GET /artworks/?is_available=true
GET /artworks/?page=1
```

## 🏛️ Subastas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/auctions/` | Listar subastas activas |
| `POST` | `/auctions/` | Crear nueva subasta |
| `GET` | `/auctions/{id}/` | Obtener detalle de subasta |
| `PATCH` | `/auctions/{id}/` | Actualizar subasta |
| `POST` | `/auctions/{id}/bid/` | Hacer una puja |

### Filtros para subastas:
```
GET /auctions/?seller={user_id}
GET /auctions/?status=active
GET /auctions/?search={término}
```

## 🛍️ Marketplace

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/marketplace/cart/` | Obtener carrito |
| `POST` | `/marketplace/cart/items/` | Agregar artículo al carrito |
| `DELETE` | `/marketplace/cart/items/{id}/` | Remover artículo del carrito |
| `POST` | `/marketplace/checkout/` | Procesar compra |
| `GET` | `/marketplace/orders/` | Obtener mis compras |
| `GET` | `/marketplace/sales/` | Obtener mis ventas |
| `POST` | `/marketplace/favorites/` | Agregar a favoritos |
| `DELETE` | `/marketplace/favorites/{id}/` | Remover de favoritos |
| `GET` | `/marketplace/favorites/` | Obtener favoritos |

## 📊 Headers Requeridos

### Para todas las requests autenticadas:
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

### Para requests sin autenticación:
```
Content-Type: application/json
```

## 🔄 Flujo de Trabajo Completo

```
1. POST /auth/register/                    → Crear cuenta artista
2. POST /auth/verify-email/                → Verificar email
3. POST /auth/login/                       → Obtener tokens
4. POST /artists/                          → Crear perfil de artista
5. POST /artworks/                         → Crear obra de arte
6. POST /auctions/                         → Crear subasta
7. GET /auctions/                          → Ver subastas activas
8. POST /auctions/{id}/bid/                → Hacer puja
9. GET /marketplace/sales/                 → Ver ventas realizadas
10. POST /marketplace/favorites/           → Agregar favoritos
```

## 🧪 Ejemplos de Payloads

### Registro
```json
{
  "email": "artista@narinocultura.uk",
  "password": "SecurePassword123!",
  "first_name": "Juan",
  "last_name": "Pérez",
  "role": "ARTISTA",
  "phone": "+57 310 1234567",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

### Crear Obra
```json
{
  "title": "Abstracción Nariñense",
  "description": "Obra de arte abstracta",
  "category_id": "uuid-aqui",
  "technique": "Acrílico",
  "dimensions": "80x100 cm",
  "year_created": 2024,
  "price": 2500000,
  "image_url": "https://example.com/artwork.jpg",
  "is_available": true
}
```

### Crear Subasta
```json
{
  "artwork_id": "uuid-aqui",
  "starting_price": 1000000,
  "reserve_price": 1500000,
  "start_date": "2026-05-20T10:00:00Z",
  "end_date": "2026-05-27T18:00:00Z",
  "description": "Subasta exclusiva"
}
```

### Hacer Puja
```json
{
  "auction_id": "uuid-aqui",
  "amount": 1200000
}
```

## 📦 Códigos de Respuesta

| Código | Significado |
|--------|------------|
| `200` | OK - Solicitud exitosa |
| `201` | Created - Recurso creado |
| `204` | No Content - Eliminado correctamente |
| `400` | Bad Request - Datos inválidos |
| `401` | Unauthorized - Token requerido/inválido |
| `403` | Forbidden - Permiso denegado |
| `404` | Not Found - Recurso no existe |
| `422` | Unprocessable Entity - Validación fallida |
| `500` | Server Error - Error interno del servidor |

## 💡 Tips Útiles

### Paginación
```
GET /artworks/?page=1&page_size=20
```

### Búsqueda
```
GET /artworks/?search=abstracción
```

### Ordenamiento
```
GET /artworks/?ordering=-created_at
GET /artworks/?ordering=price
```

### Múltiples filtros
```
GET /artworks/?artist={id}&category={id}&is_available=true
```

## 🔗 Variables de Ambiente (Postman)

```
{{base_url}}                 → http://localhost:8000/api/v1
{{access_token}}             → Token JWT actual
{{refresh_token}}            → Token para refrescar
{{artist_id}}                → ID del perfil artista
{{artwork_id}}               → ID de la obra
{{auction_id}}               → ID de la subasta
{{category_id}}              → ID de la categoría
```

---

📅 **Última actualización:** Mayo 15, 2026
🔗 **Repositorio:** Nariño Cultura Backend
