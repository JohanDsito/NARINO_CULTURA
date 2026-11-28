# Registro de cambios

Versiones de Nariño Cultura con [versionado semántico](https://semver.org/lang/es/). Cada versión es una etiqueta
`vX.Y.Z` sobre `main`, la rama que está en producción. El flujo de trabajo está en [docs/FLUJO_GIT.md](docs/FLUJO_GIT.md).

## [1.3.0] — 2026-11-28

Rediseño Carnaval en la web, app lista para Google Play y dos cambios de seguridad en el backend: el administrador ya no
puede dejarse sin acceso y el refresh token rota de verdad. Backend con 100 % de cobertura. **No hay migraciones.**

### Seguridad (cambia el comportamiento en producción)

- **El refresh token rota de verdad** (#214). `auth/token/refresh/` devuelve `{access, refresh}` y pone en lista negra el
  refresh usado; antes solo daba un `access` nuevo y el refresh nunca caducaba por uso. Rechaza a usuarios inactivos o
  eliminados y, si dos renovaciones llegan a la vez con el mismo refresh, solo una funciona (la otra recibe 400).
- **Un admin no puede quitarse el rol, suspenderse ni eliminarse** (#210): responde 400 `admin_self_change`. Tampoco se
  puede dejar el sistema sin ningún administrador activo (400 `last_admin`). Antes solo lo impedía la web.

### Backend

- Versión de la API en 1.3.0 (documentación OpenAPI y raíz `/` de la API, que decía 1.0.0).
- Cobertura con ramas al **100 %** (#212, #213): WebSocket de subastas, capa de IA y ramas sueltas. Se quitó un chequeo
  inalcanzable en `follow` de artistas, sin cambiar el comportamiento.
- Ajustes `e2e` y comando `seed_demo --confirmar` para las pruebas end-to-end (#209). Se niegan a correr contra Railway y
  no están en el Procfile ni en el Dockerfile.

### Web

- **Rediseño Carnaval** (#202, #203, #204): neutros, seis acentos, Inter y modo claro/oscuro del sistema (#202); cada
  sección con su color y precios en naranja (#203); paneles de admin, artista y comprador revisados con sesión iniciada,
  con el gráfico de ingresos que salía negro en oscuro corregido (#204).
- **Eliminar cuenta, cambiar roles, suspender y restaurar usuarios** desde la web, con diálogo de confirmación accesible
  (#207).
- Guarda el refresh rotado y hace una sola renovación a la vez; si falla, cierra la sesión (#214).

### App móvil

- **Lista para Google Play** (#205): identificador `uk.narinocultura.app`, firma de release con llave propia, ícono y
  pantalla de inicio de la marca, URL del backend por `--dart-define` y guía en `narino_mobile/docs/PUBLICACION.md`.
  Versión `1.3.0+3`.
- Las coordenadas de los eventos llegan como texto desde la API y rompían la agenda y el detalle: ahora se leen bien
  (#211).
- Las pruebas de integración ya no pueden tocar producción (#206).
- Pruebas que confirman que guarda el refresh rotado (#214); la app ya lo hacía desde el 2026-11-06.

### Pruebas y CI

- **e2e de la web con Playwright** (8 pruebas: registro, compra con Wompi simulado, subasta en vivo y eventos) y
  Lighthouse como aviso, contra un backend local (#209).
- Script de rendimiento `tools/rendimiento/medir_api.py` (#208): en producción, con 300 GET públicos y
  5 a la vez, p95 de 383 ms y 0 % de errores.
- Cifras de esta versión: backend **838 pruebas** y **100 %** de cobertura con ramas; web **130 pruebas** y 8 e2e; app
  **429 pruebas**.

### Despliegue

- **Sin migraciones nuevas** desde v1.2.0 (`makemigrations --check` sin cambios). Railway ejecuta `migrate` al arrancar,
  así que no hace falta ningún paso manual.
- **Solo el backend está desplegado** (Railway, desde `main`). La web todavía no está publicada en ningún hosting y la
  app no está en Google Play: solo hay APK de prueba.
- **Sesiones abiertas (#214):** los refresh emitidos antes del despliegue siguen sirviendo y rotan sin error. Desde la
  primera renovación cada sesión recibe un refresh nuevo y el anterior queda en lista negra.
  - La app guarda el refresh rotado desde el 2026-11-06, así que los APK de prueba 1.2.0 y 1.3.0 no pierden la sesión.
    Un APK compilado antes de esa fecha la pierde en la segunda renovación: hay que iniciar sesión otra vez o instalar
    el APK 1.3.0.
  - La web se publicará ya con 1.3.0, que guarda el refresh rotado. Una web anterior a 1.3.0 corriendo en local contra
    producción pierde la sesión en la segunda renovación.

## [1.2.0] — 2026-11-21

Primera versión que llega a producción por una rama `release/*` de Git Flow. Integra la app móvil y la limpieza de la web
en el repositorio principal, completa funcionalidades que el backend ya ofrecía y arregla las compras directas.

### Backend

- **Las reservas de compra directa vencen** (#198). Al hacer checkout las obras quedan reservadas solo durante
  `DIRECT_ORDER_PAYMENT_HOURS` (2 h). Una tarea de Celery Beat cada 5 minutos las devuelve al catálogo si no se pagó.
  Antes quedaban reservadas para siempre. Las compras pendientes que ya existían reciben plazo con la migración
  `marketplace.0005`.
- **Correo al artista cuando vende**, con sus obras y lo que le corresponde (#198).
- **Pago y comprobante de Wompi en las órdenes**: campo `payment` (#198).
- **Recordatorio a los inscritos 24 h antes de cada evento** (RF33, #190). Llega por la bandeja y por correo, una sola
  vez.
- **El historial de ventas se conserva** si el comprador elimina su cuenta (#186). La orden guarda su nombre y su
  correo (migración `marketplace.0004`).
- **Búsqueda de artistas** (`?search=`), **filtros por día en eventos** (`start_date__gte`/`__lte`, hora de Colombia) y
  **filtros y fecha de registro en el admin de usuarios** (#188).
- La cobertura mínima de IA mide los archivos nuevos de la v1.1.0 (#195).

### Web

- Limpieza completa (#178): 0 errores de TypeScript y de lint, tests en verde y contratos de la API corregidos.
- Las carpetas `pages/auth` y `pages/home` se renombraron a minúsculas (#187). El build fallaba en Linux.
- **Búsqueda de artistas en el servidor** y **bandeja de notificaciones** con contador en la campana (#196).
- **Favoritos**: guardar obras y página «Mis favoritos» (#197).
- **Quitar obras del carrito**, **plazo de pago y comprobante en Mis pedidos**, e **inscripción a eventos** con
  «Ya estás inscrito» y cancelar (#199).

### App móvil

- La app Flutter `narino_mobile/` entra al repositorio principal (#179), con el rediseño Carnaval completo.
- CI propio: análisis, tests y APK de prueba descargable en cada PR (#189).

### Integración continua y flujo de trabajo

- Git Flow con `develop`, `feature/*`, `release/*` y `hotfix/*` (#183).
- CI de la web (#187) y de la app (#189), además del backend.

## [1.1.0] — 2026-11-20

- **La IA corre dentro de Django** (#191). Usa Gemini y Groq por REST, con respaldo por reglas; se eliminó el
  microservicio aparte. El chat responde siempre, en texto plano y en alrededor de un segundo (#192).
- Los afiches de eventos se pueden subir como archivo y la IA tiene límites de uso por minuto (#193).

## [1.0.1] — 2026-11-20

- **Hotfix**: seis errores 500 (#182) al borrar cuentas, obras o usuarios con ventas, en el webhook de Wompi con
  referencias ajenas, con fechas imposibles en afiches y en la popularidad de músicos sin obras.
- El panel `/admin/` de producción vuelve a funcionar: faltaba `collectstatic` (#180).
- El CI exige cobertura del 95 % con ramas y del 90 % en cada módulo crítico (#180).

[1.3.0]: https://github.com/JohanDsito/NARINO_CULTURA/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/JohanDsito/NARINO_CULTURA/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/JohanDsito/NARINO_CULTURA/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/JohanDsito/NARINO_CULTURA/releases/tag/v1.0.1
