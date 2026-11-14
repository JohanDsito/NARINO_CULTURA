# Nariño Cultura — Frontend web

SPA en React 19 + TypeScript + Vite para la plataforma Nariño Cultura (artistas, obras,
marketplace, subastas, eventos y músicos). Consume la API Django de `Backend/`.

## Puesta en marcha

```bash
npm ci
npm run dev          # http://localhost:5173
```

Variables de entorno (`.env.local`):

| Variable            | Descripción                                                        |
|---------------------|--------------------------------------------------------------------|
| `VITE_API_BASE_URL` | Host del backend. Si termina en `/api/v1` se recorta solo. Por defecto, producción en Railway. |

## Scripts

| Comando              | Qué hace                                                    |
|----------------------|-------------------------------------------------------------|
| `npm run dev`        | Servidor de desarrollo con HMR                              |
| `npm run typecheck`  | `tsc -b`: app, tests y `vite.config.ts`                     |
| `npm run lint`       | ESLint                                                      |
| `npm test`           | Vitest una vez (`npm run test:watch` para modo observador)  |
| `npm run build`      | Typecheck + build de producción en `dist/`                  |
| `npm start`          | Sirve `dist/` (Railway usa `$PORT`)                         |

Antes de subir cambios: `npm run typecheck && npm run lint && npm test`.

## Estructura de `src/`

```
api/          Un módulo por recurso del backend (artworks.api.ts, admin.api.ts...).
              Todas las llamadas pasan por axiosInstance (token + refresh automático).
components/
  ui/         Primitivas del design system: Button, Badge, Card, Input, Select, Skeleton...
  layout/     Navbar, footer, PageShell, PageLoader, ErrorBoundary.
  auth/ artist/ musician/ events/ profile/ ai/
              Componentes de dominio reutilizables (formularios, tarjetas, widgets).
constants/
  routes.ts   Rutas de la app (ROUTES).
  labels.ts   Etiquetas en español de los valores del backend (estados, roles, tipos).
  roles.ts    Roles para las rutas protegidas.
hooks/        useAuth (login/logout), useCartCount, useStartPayment (Wompi)...
pages/        Una carpeta por sección; cada página se carga en diferido desde el router.
router/       Definición de rutas y protección por rol.
services/     WebSocket de subastas en vivo.
store/        Estado global con Zustand: sesión, carrito de invitado y tema.
types/        Tipos de dominio, uno por archivo; importar siempre desde '@/types'.
utils/        cn(), formatCurrency(), mensajes de error de la API...
test/         Setup de Vitest.
```

## Convenciones

- **Colores**: solo tokens del design system (`bg-bg-card`, `text-text-secondary`, `text-tierra`,
  `bg-error/10`...). Las variables viven en `src/index.css` (claro y `.dark`) y el config de
  Tailwind admite opacidad (`/10`, `/30`). No usar clases sueltas de shadcn
  (`bg-muted`, `text-foreground`...): no existen en el tema. Ver `DESIGN_SYSTEM.md`.
- **Datos del servidor**: React Query. En `queryFn` siempre una flecha (`() => getX()`), nunca la
  función directa: React Query le pasaría su contexto como primer argumento.
- **Formularios con datos cargados**: inicializar el estado una vez (`useState(() => ...)`) en
  un componente hijo con `key`, en lugar de copiar props a estado dentro de un `useEffect`.
- **Precios**: `formatCurrency()` de `@/utils` (acepta los strings que envía DRF).
- **Errores de API**: `getApiErrorMessage(error)` para el texto del toast.
- **Nombres de archivo**: componentes en `kebab-case.tsx`; páginas en `PascalCasePage.tsx`.

## Pendientes que dependen del backend

- `GET /artists/?search=` se ignora (falta `search_fields`); la búsqueda de artistas filtra en el cliente.
- El calendario de eventos envía `start_date__gte/lte`, pero `EventViewSet` no tiene esos filtros.
- Crear evento envía `flyer` y `ticket_url`, que `EventSerializer` no tiene y descarta.
- `GET /admin/users/` no devuelve la fecha de registro.
- Las listas paginadas (pedidos, ventas, obras en admin) solo muestran la primera página.
