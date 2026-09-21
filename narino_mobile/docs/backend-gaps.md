# Huecos de contrato pendientes en el Backend

Este documento registra discrepancias entre lo que la app Flutter necesita y lo que el
backend (Django REST) expone hoy. Ninguno de estos puntos se corrige desde el frontend
porque requiere cambios en `Backend/`. Se documentan aquí para que quien trabaje en el
backend los tenga en el radar.

## 1. Falta `is_following` en `ArtistProfileSerializer`

- **Dónde**: `Backend/narinocultura_backend/apps/artists/serializers.py`
- **Síntoma en la app**: al abrir el perfil público de un artista
  (`narino_mobile/lib/features/profile/presentation/screens/artist_public_profile_screen.dart`),
  el botón "Seguir" siempre arranca en estado "no siguiendo", sin importar si el usuario
  actual ya lo sigue.
- **Causa**: `ProfileModel.esSeguido` (`narino_mobile/lib/features/profile/domain/profile_model.dart`)
  busca `is_following` / `es_seguido` en la respuesta, pero el serializer de artistas no
  define ese campo en absoluto.
- **Referencia de cómo resolverlo**: `apps/musicians/serializers.py` ya implementa este
  mismo campo correctamente en `MusicianProfileSerializer` y `MusicianProfileListSerializer`
  vía un `SerializerMethodField` que revisa `obj.followers.filter(user=request.user).exists()`.
  Se podría replicar el mismo patrón en `ArtistProfileSerializer`.

## 2. No existe el endpoint `/api/v1/users/me/following/`

- **Dónde**: no hay ninguna ruta registrada para esto en `Backend/narinocultura_backend/apps/artists/urls.py`
  (ni en ningún otro `urls.py` del backend).
- **Síntoma en la app**: la pantalla "Siguiendo"
  (`narino_mobile/lib/features/profile/presentation/screens/following_screen.dart`) siempre
  aparece vacía. `ProfileService.getMyFollowing()` recibe un 404 y lo traga silenciosamente
  devolviendo una lista vacía.
- **Qué necesitaría la app**: un endpoint que devuelva la lista de artistas que el usuario
  autenticado sigue actualmente (probablemente una acción `me/following` en
  `ArtistProfileViewSet`, similar a como `MusicianProfileViewSet` expone `follow`).

## 3. No existe ningún endpoint de IA para sugerir categoría o generar descripción de una obra nueva

- **Dónde**: el frontend (`narino_mobile/lib/features/artworks/presentation/screens/publish_artwork_screen.dart`,
  ahora movido a `narino_mobile/lib/features/ai/data/ai_service.dart`) llama a
  `POST /ai/suggest-category/` y `POST /ai/generate-description/`. Ninguna de las dos rutas
  existe en el backend (no hay match en ningún `urls.py`).
- **Lo único que existe hoy**: `POST /api/v1/artworks/{id}/ai-enhance/`
  (`apps/artworks/views.py`, acción `ai_enhance`), que:
  - Requiere una obra **ya creada** (necesita `artwork.id`), por lo que no sirve para sugerir
    categoría/descripción mientras se está *componiendo* una obra nueva (antes de guardarla).
  - Depende de un microservicio externo (`settings.AI_SERVICE_URL` en
    `services/ai_service.py`), que puede no estar configurado en este entorno.
  - Devuelve `ai_tags` + `ai_description`, una forma de respuesta distinta a lo que el
    frontend espera (`categoria` / `descripcion`).
- **Síntoma en la app**: los botones "Sugerir categoría con IA" y "Generar descripción con IA"
  al publicar una obra nueva nunca han funcionado — siempre caen en el mensaje de error
  genérico.
- **Qué necesitaría la app**: o bien (a) un endpoint nuevo que acepte título/categoría sin
  requerir una obra ya persistida, o (b) rediseñar el flujo para crear la obra primero (como
  borrador) y luego ofrecer el enriquecimiento con IA vía `ai-enhance`, ajustando también la
  respuesta a lo que esa acción realmente devuelve.
- **No se tocó nada**: el frontend sigue llamando a las mismas rutas rotas; queda pendiente
  a propósito hasta que el equipo de backend decida el diseño correcto.

## 4. La acción `register` de eventos no acepta cancelar la inscripción (solo POST)

- **Dónde**: `Backend/narinocultura_backend/apps/events/views.py`, acción
  `register` (línea ~115): `@action(detail=True, methods=["post"], url_path="register")`.
- **Síntoma en la app**: en el detalle de un evento, el botón de recordatorio permite
  "activar" (POST, ya funciona) pero no "cancelar" (el frontend intenta un `DELETE` al mismo
  endpoint, que el backend rechazará con 405 Method Not Allowed).
- **Nota**: ya se corrigió un bug aparte en el frontend donde esa llamada iba a una URL sin
  el prefijo `/api/v1/` (por eso antes fallaba con 404 en vez de 405). Ahora que la URL es
  correcta, el registro (POST) funciona, pero cancelarlo seguirá fallando hasta que el
  backend agregue soporte.
- **Qué necesitaría la app**: que la acción `register` también acepte `methods=["post", "delete"]`,
  y que el método `delete` borre el `EventRegistration` correspondiente
  (`EventRegistration.objects.filter(event=event, user=request.user).delete()`).

## 5. El app `notifications` del backend no tiene API — solo un modelo

- **Dónde**: `Backend/narinocultura_backend/apps/notifications/` solo contiene
  `models.py` (y `admin.py`/`apps.py`/migraciones). No existen `views.py`, `serializers.py`
  ni `urls.py` — por lo tanto ninguna ruta bajo `/api/v1/notifications/...` existe.
- **Síntoma en la app**: toda la sección de notificaciones falla en silencio porque el
  frontend está codeado defensivamente para tragar 404s:
  - La bandeja de notificaciones (`notifications_screen.dart` /
    `NotificationsService.list()`) siempre muestra "vacío".
  - Marcar como leída / marcar todas como leídas son no-ops silenciosos.
  - "Preferencias de notificaciones de eventos"
    (`event_notification_preferences_screen.dart`) solo guarda en el almacenamiento local
    del celular (`flutter_secure_storage`); nunca sincroniza con el servidor, así que el
    usuario nunca recibirá notificaciones reales basadas en esas preferencias.
- **Qué necesitaría la app**: una API real bajo `/api/v1/notifications/` — al menos:
  - `GET /api/v1/notifications/` (lista, con filtro `no_leidas`)
  - `PATCH /api/v1/notifications/{id}/read/` (marcar una como leída)
  - `POST /api/v1/notifications/read-all/` (marcar todas)
  - `GET`/`PATCH /api/v1/notifications/event-preferences/` (preferencias por tipo de evento
    y por artista favorito)
  - Ver `apps/events/views.py` (`NotificationService.send(...)`) para lo que ya se está
    generando del lado del backend pero nunca llega a exponerse por API — el modelo de datos
    del app `notifications` probablemente ya sirve como punto de partida.

## Nota de contexto: flyer de eventos (ya resuelto en frontend, no requiere acción)

Al publicar un evento, el flyer se descartaba en silencio (nunca se enviaba al backend).
Ya se corrigió del lado de la app: como `Event.image_url` es un `URLField` (no hay
`ImageField`/multipart para eventos, a diferencia de `artworks`/`artists`/`musicians`), se
cambió el selector de imagen local por un campo de texto donde el organizador pega una URL
ya alojada. Si en el futuro se quiere subir el archivo directamente desde el celular, el
backend necesitaría agregar un campo de archivo + endpoint multipart para `Event`, siguiendo
el mismo patrón que ya usan las otras apps.

---

*Generado a partir de una auditoría del flujo de login/perfil hecha el 2026-09-20, y
ampliado el 2026-09-21 con hallazgos de una revisión de arquitectura (llamadas a la API
movidas a repositorios) en las features de artworks, events y notifications. Los bugs
que sí eran corregibles desde el frontend (avatar, nombre, estado de seguimiento en
músicos, reset de sesión, vistas vs. favoritos de una obra, URL de registro a eventos,
paginado innecesario al filtrar por artista) ya fueron corregidos en el código de
`narino_mobile/lib/`.*
