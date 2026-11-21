# Registro de cambios

Versiones de Nariño Cultura con [versionado semántico](https://semver.org/lang/es/). Cada versión es una etiqueta
`vX.Y.Z` sobre `main`, la rama que está en producción. El flujo de trabajo está en [docs/FLUJO_GIT.md](docs/FLUJO_GIT.md).

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

[1.2.0]: https://github.com/JohanDsito/NARINO_CULTURA/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/JohanDsito/NARINO_CULTURA/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/JohanDsito/NARINO_CULTURA/releases/tag/v1.0.1
