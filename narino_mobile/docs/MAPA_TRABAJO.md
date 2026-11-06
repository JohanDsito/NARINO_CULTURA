# Mapa de trabajo — App móvil Nariño Cultura

> Documento vivo. Se actualiza en cada paso. Última actualización: 2026-11-05.
> Rama: `mobile-Valery` · Respaldo previo al sync: `backup/mobile-Valery-pre-merge`.

Leyenda: ✅ hecho · 🔧 en curso · ⏳ pendiente · 🚫 bloqueado por backend · 💡 mejora sugerida

---

## Fase 1 — Traer el backend de `main` ✅

- ✅ `git fetch` → `mobile-Valery` estaba 183 commits detrás de `origin/main`.
- ✅ No se hizo `git merge` completo: genera ~60 conflictos por renombres y metería `Front/` en la
  rama móvil. Se siguió el patrón ya usado en la rama (commits `ff1d669`, `d6a68a2`):
  `git checkout origin/main -- Backend .github`.
- ✅ Se re-aplicó el único cambio propio de mobile sobre el backend (commit `40ae5be`:
  `is_following`, `average_rating`, `reviews_count` en serializers de músicos + contexto `request`).
- ✅ Tests backend: **260/260 OK** (`config.settings.test`, SQLite en memoria).
- ⚠️ **Producción (`narinocultura-production.up.railway.app`) corre `main`, no esta rama.**
  Lo que se cambie en `Backend/` aquí NO llega a la app hasta que se suba a `main` y se despliegue.
  Regla: **la app debe funcionar con el contrato actual de `main`** y tolerar campos ausentes.
  Confirmado en producción: músicos **no** traen `is_following` / `average_rating`.

Novedades del backend que impactan la app:
| HU | Cambio | Impacto móvil |
|---|---|---|
| B09 | API real de notificaciones (`/notifications/`, `/unread-count/`, `/read-all/`, `/{uuid}/read/`) | Antes se tragaban 404; ahora hay datos. IDs son **UUID** |
| B03/B06 | WebSocket subastas: mensajes `connected`, `snapshot`, `bid_placed`, `auction_closed` | Revisar provider de detalle de subasta |
| B04 | Orden de pago para el ganador (`payment_order_id` en la subasta, solo lo ve el ganador) | El modelo leía `order_id` → nunca encontraba la orden |
| B05 | Inscripción a eventos para cualquier usuario autenticado | OK, sin cambios |
| B02 | Solo se editan/eliminan subastas `PENDIENTE` | Las subastas nuevas quedan `PENDIENTE` hasta aprobación admin |
| — | `artists/following/`, `musicians/following/`, `followers` | Reemplaza `users/me/following/` (no existe) |

---

## Fase 2 — Bugs e inconsistencias de contrato ✅ (pendientes solo los 🚫 de backend)

### Contrato real del backend (resumen)
- Paginación: `{count, next, previous, results}` · `page_size` máx 100 · throttle anónimo 200/h.
- Artistas y músicos se buscan por **slug**, no por UUID.
- `GET /artworks/{id}/` **incrementa `views_count`** cada vez → no usarlo para "enriquecer" listas.
- Obras: filtros `status`, `category` (id), `artist` (slug), `mine=true`, `search`;
  ordering `created_at`, `price`, `views_count`.
- Subastas: filtro solo `status`. Serializer NO trae título/imagen de obra ni lista de pujas.

### Hallazgos y estado
| # | Área | Problema | Estado |
|---|---|---|---|
| 1 | Notificaciones | `id` y `referenciaId` se parseaban como `int` pero son UUID → `id=0`, marcar leída fallaba | ✅ id String, ruta desde `data`, marcado optimista |
| 2 | Notificaciones | `?no_leidas=true` funciona; no se usa `unread-count` para el badge | ✅ badge usa `unread-count/` |
| 3 | Notificaciones | Preferencias de eventos (`event-preferences/`) no existen en backend | 🚫 (dejar local) |
| 4 | Catálogo | Envía `categoria`, `tecnica`, `precio_min/max` y ordering en español (`precio`, `-creado_en`) → el backend los ignora | ✅ categorías reales del backend (id), ordering `price`/`-created_at`/`-views_count`, técnica y precio filtrados en la app |
| 5 | Perfil | "Siguiendo" llama `users/me/following/` (404) → usar `artists/following/` + `musicians/following/` | ✅ artistas + músicos, navega a la pantalla correcta |
| 6 | Perfil | `getMyProfile` recorre TODA la lista de artistas y TODAS las obras para contar | ✅ 1 petición `?mine=true` (count + slug); solo recorre artistas si no tiene obras |
| 7 | Perfil | Portafolio (`artists/{id}/portfolio/`) no existe en backend | 🚫 |
| 8 | Perfil/Seguridad | `change-email`, `sessions`, `resend-verification` no existen | 🚫 (mensaje claro en UI) |
| 9 | Marketplace | Carrito/favoritos hacen 1 `GET /artworks/{id}` por ítem → infla vistas y gasta throttle | ✅ una consulta de lista. Además favoritos leía `artwork_id` (no existe) → nunca mostraba imagen/precio |
| 10 | Marketplace | `orders/{id}/` no existe (ya hay fallback a la lista) | ✅ (fallback existente) |
| 11 | Subastas | Tarjetas muestran "Obra"/"Artista" sin imagen: el serializer solo trae el UUID de la obra | ✅ se cruzan con la lista de obras (`EN_SUBASTA` y luego catálogo) |
| 12 | Subastas | Historial envía `participante=me` / `artista=me` → el backend los ignora y muestra TODAS | ✅ filtro en la app por id de usuario (`seller`, `highest_bidder`, `winner`). Limitación: "participé" = voy ganando o gané (el backend no expone pujas) |
| 13 | Subastas | Ganador: se leía `order_id`, el backend manda `payment_order_id` | ✅ + ganador/vendedor se comparaban con el slug del artista en vez del id de usuario |
| 14 | Subastas | WebSocket: revisar que el provider procese `snapshot` / `bid_placed` / `auction_closed` | ✅ puja en vivo se agrega a la lista, snapshot respeta estado, al cerrar se recarga para traer la orden |
| 15 | Subastas | No hay historial de pujas por REST | 🚫 |
| 16 | Eventos | Cancelar inscripción (DELETE) no existe → 405 | ✅ mensaje claro; "ya inscrito" marca el estado. Falta endpoint en backend |
| 17 | IA | `/ai/suggest-category/`, `/ai/generate-description/`, `/ai/recommendations/`, `/ai/artist-stats/` no existen | 🚫 |
| 18 | Músicos | Producción no envía `is_following` → el botón seguir arranca en "Seguir" | 🚫 hasta desplegar `40ae5be` |
| 19 | Artistas | `ArtistProfileSerializer` no trae `is_following` | 🚫 (se puede deducir con `artists/following/`) |
| 20 | Cuenta | Eliminar cuenta se bloqueaba si existía CUALQUIER subasta activa en la plataforma (`artista=me` ignorado) | ✅ solo cuenta las subastas propias |
| 21 | Eventos | Mensaje 403 decía "solo gestores"; el backend permite artistas, gestores y admin | ✅ |
| 22 | Roles | El backend manda `ADMINISTRADOR` / `GESTOR_CULTURAL`; la app comparaba con `admin` / `gestor` → gestores no veían "publicar evento" y admin no tenía permisos | ✅ `normalizeRole()` en `user_role_provider` |
| 23 | Roles | `currentUserIdProvider` parseaba el UUID como `int` → siempre `null` | ✅ ahora `String` |
| 24 | Obras | Detalle: el artista no veía editar/eliminar en SU obra (comparaba id de usuario con id de perfil) | ✅ compara slug del perfil con `artist_slug` |
| 25 | Eventos | Botón publicar evento oculto para artistas (el backend sí los deja) | ✅ |
| 26 | Registro | Siempre enviaba `role: ARTISTA` → nadie podía registrarse como comprador | ✅ elección "Crear y vender" / "Descubrir y comprar" |
| 27 | Verificar correo | "Reenviar" fallaba en silencio (endpoint no existe) | ✅ aviso claro |
| 28 | Acceso | En pantallas bajas el contenido se cortaba en vez de desplazarse | ✅ |
| 29 | Detalle de obra | "Agregar al carrito" solo mostraba "Carrito disponible próximamente" → nadie podía comprar desde el detalle | ✅ agrega de verdad, estado "ya en tu carrito" |
| 30 | Obras | `categoria` guardaba el id ("1") y se mostraba como nombre; al editar no se recuperaba bien | ✅ `categoriaId` + nombre desde `category_detail` |
| 31 | Catálogo | La búsqueda hacía 1 petición por letra | ✅ espera 450 ms |
| 32 | Filtros | "Aplicar" hacía 4 peticiones; no se podía quitar el rango de precio | ✅ `aplicarFiltros()` una sola vez + `clearPrecio` |
| 33 | Publicar | Permitía elegir varias imágenes pero solo subía la primera | ✅ una sola portada (galería o cámara) |
| 34 | Publicar | Botones de IA siempre fallaban (endpoints inexistentes) | ✅ ocultos con `_kIaDisponible` |
| 35 | Obras | Precio 0 (exhibición) se mostraba como "$0" a la venta | ✅ 0 = "En exhibición" |
| 36 | Tienda | Al abrirla reiniciaba los filtros del Catálogo (estado compartido) y solo veía la 1.ª página | ✅ consulta propia `status=DISPONIBLE` |
| 37 | Pago | El sondeo de Wompi seguía cada 5 s para siempre al salir de la pantalla | ✅ se detiene al salir y a los 10 min |
| 38 | Resultado de pago | "Reintentar" llevaba al carrito, que ya está vacío | ✅ vuelve a pagar la misma orden |
| 39 | Carrito | No avisaba obras vendidas/en subasta y las sumaba al total | ✅ aviso + se excluyen del total y bloquean el pago |
| 41 | Subastas | La lista redibujaba toda la pantalla cada segundo por la cuenta regresiva | ✅ `NcCountdown` por tarjeta |
| 42 | Subastas | La app exigía +5 % para pujar; el backend acepta cualquier monto mayor al actual | ✅ regla real + montos sugeridos (+5/+10/+20 %) |
| 43 | Subastas | Al crear decía "Subasta abierta" pero queda PENDIENTE hasta aprobación | ✅ "Enviada a revisión" |
| 44 | Subastas | Una subasta pendiente se mostraba como "cerrada" | ✅ fases: en revisión, próximamente, en vivo, finalizada, cancelada |
| 45 | Historial | Pestañas con texto inactivo fijo en blanco (invisible en modo claro) | ✅ |
| 46 | Subastas | La tarjeta mostraba el precio base aunque hubiera pujas (`total_pujas` no existe) | ✅ usa `current_price` y el líder |
| 47 | Eventos | Solo llegaba la 1.ª página (sin `page_size`) → calendario incompleto | ✅ `page_size=100`, orden por fecha |
| 48 | Eventos | "Convocatoria" no existe en el backend (se guardaba como "Otro"); faltaba "Espectáculo" en preferencias | ✅ tipos reales |
| 49 | Eventos | El filtro "por artista" nunca encontraba nada (el backend no tiene artistas en eventos) | ✅ búsqueda por nombre, lugar o descripción |
| 50 | Eventos | Un evento en curso se marcaba como pasado (usaba la fecha de inicio) | ✅ usa `end_date` |
| 51 | Eventos | Cambiar de calendario a lista mezclaba eventos pasados | ✅ se cargan todos y la vista decide; botón "Ver pasados" |
| 52 | Publicar evento | Campo "artistas" que nunca se enviaba; duración fija de 2 h; decía "publicado" aunque quedara en borrador | ✅ sin campo, duración elegible, aviso de borrador |
| 53 | Eventos | Gestores veían borradores mezclados sin distinguir | ✅ insignia "Borrador" |
| 40 | Ventas | Una orden con obras de varios artistas suma el total completo; `OrderItemSerializer` no dice de quién es cada ítem | 🚫 pedir `artist_slug` en el ítem |

---

## Fase 3 — Nueva interfaz (por pantallas) 🔧

Fuente: `narino_cultura_movil_1_design_system.html` y `narino_cultura_movil_2_inicio.html`.

### Tokens del design system
| Token | Oscuro (por defecto) | Claro |
|---|---|---|
| bg | `#050505` | `#F5F5F7` |
| bg-card | `#121214` | `#FFFFFF` |
| bg-glass | `rgba(18,18,20,.72)` | `rgba(255,255,255,.78)` |
| text-primary | `#F5F5F7` | `#1D1D1F` |
| text-secondary | `#86868B` | `#6E6E73` |
| border | `rgba(255,255,255,.08)` | `rgba(0,0,0,.06)` |
| tomate | `#FF3300` | `#FF3300` |
| naranja-neón | `#FF6600` | `#FF6600` |
| azul-neón (acción principal) | `#00E5FF` | `#0055FF` |
| oro-tierra | `#D4AF37` | `#B8860B` |
| magenta | `#FF0055` | `#E50050` |

- Tipografía **Inter** 300–800; títulos 800 con letter-spacing negativo (-0.04em).
- Botón primario: píldora, 48 px alto, fondo azul-neón, texto negro (blanco en claro), glow en oscuro.
- Botón secundario: píldora, borde `border`, fondo blanco 10 % (negro 5 % en claro).
- Tarjetas: radio 22, borde 1 px; en oscuro **borde degradado azul→naranja**.
- Ítem de agenda: radio 16, hora en naranja 12/700, título 15/600, desc 13 secundaria.
- Fondo "carnaval": orbes difuminados (tomate, naranja, azul, magenta) + formas (sol, nota, lente) + partículas de talco, con parallax.
- Header y tabbar en vidrio (blur 20–24). Tab activa en azul-neón. Toast píldora.
- Logo: cuadro 34 px radio 10 con "N" sobre degradado naranja→magenta.

### Referencia web (`Front/`, traído de `main`)
- La web **todavía usa la paleta vieja** (tierra/oro, Playfair Display + DM Sans, `DESIGN_SYSTEM.md`).
  El diseño nuevo "Carnaval" solo existe en los dos HTML → la app móvil es la primera en adoptarlo.
- Se usa como referencia de **contenido y flujos**, no de estilo.

Guía completa de color y componentes: **`docs/DISENO_CARNAVAL.md`**.

### Cómo quedó montado
- `core/theme/app_colors.dart`: paleta nueva + **alias de nombres viejos** (`tierraProfunda`, `oroClaro`…) apuntando a los nuevos colores, para que ninguna pantalla se rompa mientras se migran.
- `core/theme/nc_theme.dart`: `context.nc` → tokens que cambian claro/oscuro (`nc.azul`, `nc.bgCard`, `nc.border`, `nc.glow`, `nc.borderGradient`…).
- `core/theme/app_typography.dart`: todo en **Inter** (antes Playfair/DM Sans/Cormorant).
- `core/theme/app_theme.dart`: botones píldora 48 px, tarjetas radio 22, inputs radio 14, snackbar tipo toast, etc.
- `shared/widgets/design/`: `CarnavalBackground`, `NcCard` (borde degradado en oscuro), `NcGlassHeader`, `NcBrand`, `NcIconButton`, `NcEventItem`, `NcTabBar`, `NcPressable`, `NcSectionHeader`.
- Codemod: se quitó el AppBar fijo "oscuro + dorado" de 39 pantallas (ahora toman el tema). Las barras sobre imagen se dejaron igual.
- Modo por defecto: **oscuro** (como el diseño). Botón ☀️/🌙 en el header de Inicio.
- `test/_preview/home_preview_test.dart`: genera capturas PNG con la fuente real (se salta en la suite normal).

### Pantallas
| Pantalla | Estado |
|---|---|
| Tema global (colores, tipografía, botones, inputs, tarjetas) | ✅ |
| Shell: tabbar vidrio + fondo carnaval con parallax | ✅ |
| Inicio (hero, disciplinas en carrusel, obras destacadas, agenda con calendario) | ✅ datos reales, sin mocks |
| Tarjeta de obra compartida (`ArtworkCard`) | ✅ |
| Login / Registro / Recuperar / Verificar correo | ✅ `AuthScaffold` común; registro con elección de rol y medidor de contraseña |
| Perfil artístico (onboarding del artista) | ✅ disciplinas con color propio, paso 2 musical con chips |
| Catálogo + filtros + Detalle de obra + Publicar/Editar + Mis obras | ✅ |
| Tienda / Carrito / Pago / Resultado / Favoritos / Compras / Orden / Ventas | ✅ acento naranja, códigos cortos de orden, estados en lenguaje claro |
| Subastas (lista, detalle, crear, historial) | ✅ oro + tomate en vivo, cuenta regresiva propia, barra de puja con montos sugeridos |
| Eventos (lista/calendario, detalle, publicar) | ✅ tomate, color por tipo, calendario compartido con Inicio |
| Músicos / Descubrimiento musical | ⏳ |
| Perfil y subpantallas | ⏳ |
| Notificaciones / Chatbot | ⏳ |

---

## Mejoras sugeridas 💡
- Agregar al backend `artworks_count` y `is_following` en `ArtistProfileSerializer` y una acción `artists/me/`.
- Exponer `artwork_title`, `artwork_image_url` y `bids_count` en `AuctionSerializer`.
- `OrderItemSerializer`: agregar `artist_slug` e imagen para calcular ventas por artista.
- Endpoint `DELETE events/{id}/register/` para cancelar inscripción.
- Desplegar el fix `40ae5be` de músicos en `main`.
- Archivos de build trackeados en git (`narino_mobile/android/build/...`) → sacarlos con `.gitignore`.

## Bitácora
- 2026-11-05 — Sync de backend desde `main` + re-aplicado fix músicos. 260 tests OK. `flutter analyze` sin issues. Auditoría de contrato.
- 2026-11-05 — Fase 2: arreglados #1, #2, #4, #5, #6, #9, #11–#14, #16, #20, #21. `flutter analyze` limpio, **352/352 tests OK**.
  Siguiente: Fase 3 (tema global → shell → Inicio).
- 2026-11-06 — Traída la carpeta `Front/` de `main`. Fase 3 arrancada: tema global, componentes, shell e Inicio.
  Arreglados además #22–#25 (roles y permisos). `flutter analyze` limpio, 352/352 tests OK.
  Pendiente visual: las pantallas restantes aún tienen fondo sólido (el carnaval solo se ve en Inicio) y
  algunos banners oscuros con texto dorado (login, registro, tienda, perfil) que se rehacen pantalla por pantalla.
- 2026-11-06 — Sistema de color carnaval para claro/oscuro (tintas con contraste ≥ 4.5:1, acento por sección,
  serpentina) en `nc_theme.dart` + guía `docs/DISENO_CARNAVAL.md`. Rediseñadas las 4 pantallas de acceso.
  Arreglados #26–#28. 352/352 tests OK.
- 2026-11-06 — Rediseño módulo de obras: perfil artístico, catálogo, filtros, detalle, publicar/editar, mis obras.
  Arreglados #29–#35. 352/352 tests OK. Siguiente: Tienda (carrito, checkout, favoritos, compras, ventas).
- 2026-11-06 — Commits organizados y push a `mobile-Valery`. Rediseño de la Tienda completa (8 pantallas).
  Arreglados #36–#39. Siguiente: Subastas.
- 2026-11-06 — Arreglo de backend para ventas por artista (`SaleSerializer`, `seller_amount`, artista e imagen por ítem) probado (262 tests) y entregado como nota; la app ya lo soporta. Rediseño de Subastas. Arreglados #41–#46. Siguiente: Eventos.
- 2026-11-06 — Rediseño de Eventos (agenda, detalle, publicar) y calendario compartido `NcMonthCalendar`. Arreglados #47–#53. Siguiente: Músicos.
