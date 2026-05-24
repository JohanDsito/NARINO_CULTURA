# Nariño Cultura

Plataforma digital de marketplace y cultura artística de la región Nariño, Colombia. Permite a artistas exhibir y subastar sus obras, a gestores culturales organizar eventos, y a compradores adquirir arte de forma segura con pagos en línea.

---

## Arquitectura General

```
┌─────────────────────────────────────────────────────┐
│                   Cliente (Browser)                  │
│          React 19 + TypeScript + Tailwind            │
└──────────────────────────┬──────────────────────────┘
                           │ HTTP/WebSocket
┌──────────────────────────▼──────────────────────────┐
│              Django 5.1 + DRF (ASGI/Daphne)          │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ │
│  │  Auth   │ │ Artworks │ │Auctions │ │ Payments │ │
│  │  Users  │ │ Artists  │ │  WS     │ │  Wompi   │ │
│  └─────────┘ └──────────┘ └─────────┘ └──────────┘ │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ │
│  │Marketpl.│ │  Events  │ │ Admin   │ │  System  │ │
│  └─────────┘ └──────────┘ └─────────┘ └──────────┘ │
└────────────┬─────────────────────────┬──────────────┘
             │                         │
    ┌────────▼───────┐      ┌──────────▼──────────┐
    │  PostgreSQL 15 │      │      Redis 7          │
    │  (datos, ORM)  │      │  (WS, cache, Celery) │
    └────────────────┘      └──────────┬───────────┘
                                       │
                         ┌─────────────▼────────────┐
                         │   Celery Worker + Beat    │
                         │  (cierre automático de    │
                         │   subastas, audit logs)   │
                         └──────────────────────────┘
```

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Framework backend | Django 5.1.7 + DRF 3.15.2 |
| Autenticación | JWT (Simple JWT) + Argon2 |
| WebSockets | Django Channels 4 + Redis |
| Tareas async | Celery 5.3 + Celery Beat |
| Base de datos | PostgreSQL 15 |
| Cache/Broker | Redis 7 |
| Documentación API | drf-spectacular (Swagger/OpenAPI 3) |
| Frontend | React 19 + TypeScript + Vite 8 |
| Estilos | Tailwind CSS 3.4 + Radix UI |
| Estado | Zustand 5 + TanStack Query 5 |
| Pagos | Wompi (pasarela colombiana) |
| Email | Brevo SMTP |
| Deploy | Railway (producción) + Docker Compose (local) |

---

## Prerrequisitos

- Python 3.11+
- Node.js 20+
- Docker + Docker Compose (recomendado para desarrollo)
- PostgreSQL 15 (si no usas Docker)
- Redis 7 (si no usas Docker)

---

## Setup de Desarrollo

### Con Docker Compose (recomendado)

```bash
# Clonar e ir al directorio
git clone <repo-url>
cd NARINO_CULTURA

# Copiar y configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales (ver tabla más abajo)

# Levantar todos los servicios
docker-compose up --build

# Crear superusuario (en otra terminal)
docker-compose exec django python manage.py createsuperuser
```

El backend quedará disponible en `http://localhost:8000`.

### Sin Docker

```bash
# Backend
cd narinocultura_backend
python -m venv ../venv
source ../venv/bin/activate  # Windows: ..\venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver

# En otra terminal — Celery worker
celery -A config worker --loglevel=info

# En otra terminal — Celery beat (cierre de subastas)
celery -A config beat --loglevel=info

# Frontend
cd ../Narino_Front
npm install
npm run dev
```

---

## Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto. Las variables marcadas como **Requerida** no tienen valor por defecto seguro.

| Variable | Requerida | Descripción | Default dev |
|----------|-----------|-------------|-------------|
| `SECRET_KEY` | ✅ | Clave secreta Django (mín. 50 chars) | unsafe-default |
| `DEBUG` | — | Modo debug | `False` |
| `ALLOWED_HOSTS` | ✅ (prod) | Hosts permitidos separados por coma | localhost,127.0.0.1 |
| `DB_ENGINE` | — | Motor de BD | `sqlite3` |
| `DB_NAME` | ✅ (postgres) | Nombre de la BD | — |
| `DB_USER` | ✅ (postgres) | Usuario de BD | — |
| `DB_PASSWORD` | ✅ (postgres) | Contraseña de BD | — |
| `DB_HOST` | ✅ (postgres) | Host de BD | — |
| `DB_PORT` | — | Puerto de BD | `5432` |
| `REDIS_URL` | — | URL de Redis | `redis://localhost:6379/0` |
| `CORS_ALLOWED_ORIGINS` | — | Orígenes CORS permitidos | `http://localhost:5173` |
| `EMAIL_HOST_USER` | ✅ | Usuario SMTP | — |
| `EMAIL_HOST_PASSWORD` | ✅ | Contraseña SMTP (App Password) | — |
| `DEFAULT_FROM_EMAIL` | — | Email remitente | `noreply@narinocultura.uk` |
| `FRONTEND_BASE_URL` | — | URL del frontend | `http://localhost:5173` |
| `WOMPI_PUBLIC_KEY` | ✅ (pagos) | Llave pública Wompi | — |
| `WOMPI_PRIVATE_KEY` | ✅ (pagos) | Llave privada Wompi | — |
| `WOMPI_INTEGRITY_KEY` | ✅ (pagos) | Llave de integridad Wompi | — |
| `USE_S3` | — | Usar S3 para imágenes | `False` |
| `AWS_ACCESS_KEY_ID` | ✅ (S3) | Credencial AWS | — |
| `AWS_SECRET_ACCESS_KEY` | ✅ (S3) | Credencial AWS | — |
| `AWS_STORAGE_BUCKET_NAME` | ✅ (S3) | Bucket S3 | — |

---

## Documentación de la API

Con el servidor corriendo, accede a:

- **Swagger UI**: `http://localhost:8000/api/docs/`
- **Schema OpenAPI**: `http://localhost:8000/api/schema/`
- **Health Check**: `http://localhost:8000/health/`
- **Admin Django**: `http://localhost:8000/admin/`

También se incluyen colecciones Postman en `docs/postman/`.

---

## Ejecutar Tests

```bash
cd narinocultura_backend

# Todos los tests
python manage.py test apps --verbosity=2

# Con cobertura
python -m coverage run manage.py test apps
python -m coverage report --show-missing
python -m coverage html  # Abre htmlcov/index.html
```

### Frontend
```bash
cd Narino_Front
npm run test          # Una sola vez
npm run test:watch    # Modo watch
npm run test:coverage # Con reporte de cobertura
```

---

## Roles del Sistema

| Rol | Puede hacer |
|-----|-------------|
| `ARTISTA` | Crear obras, iniciar subastas, ver sus ventas |
| `COMPRADOR` | Comprar obras, pujar en subastas, agregar favoritos |
| `GESTOR_CULTURAL` | Crear y publicar eventos culturales |
| `ADMINISTRADOR` | Acceso total — moderar contenido, ver métricas |

---

## Flujos Principales

### Compra directa
1. Comprador agrega obra al carrito → `POST /api/v1/marketplace/cart/items/`
2. Hace checkout → `POST /api/v1/marketplace/checkout/`
3. Inicia pago Wompi → `POST /api/v1/payments/initiate/`
4. Wompi llama webhook → `POST /api/v1/payments/wompi-webhook/`
5. Orden queda `PAGADO`, artista recibe notificación

### Subasta
1. Artista crea subasta → `POST /api/v1/auctions/`
2. Compradores se conectan via WebSocket → `ws://host/ws/auctions/<id>/`
3. Pujas en tiempo real → `POST /api/v1/auctions/<id>/bid/`
4. Celery Beat cierra la subasta automáticamente al llegar `ends_at`
5. Ganador queda registrado, artista ve el resultado

---

## Linting

```bash
# Backend (ruff)
ruff check narinocultura_backend/

# Frontend (ESLint)
cd Narino_Front && npm run lint
```

---

## Estructura de Carpetas

```
NARINO_CULTURA/
├── narinocultura_backend/      # Backend Django
│   ├── apps/                   # Aplicaciones Django
│   │   ├── users/              # Autenticación y usuarios
│   │   ├── artists/            # Perfiles de artistas
│   │   ├── artworks/           # Catálogo de obras
│   │   ├── marketplace/        # Carrito, órdenes, favoritos
│   │   ├── auctions/           # Sistema de subastas
│   │   ├── payments/           # Integración Wompi
│   │   ├── events/             # Eventos culturales
│   │   ├── administration/     # Panel administrativo
│   │   ├── notifications/      # Log de notificaciones
│   │   └── system/             # Health check, middleware, logs
│   ├── config/                 # Settings, URLs, ASGI, Celery
│   ├── services/               # Lógica de negocio
│   ├── utils/                  # Utilidades compartidas
│   └── tests/                  # Factories de tests
├── Narino_Front/               # Frontend React
│   └── src/
│       ├── api/                # Clients HTTP
│       ├── components/         # Componentes reutilizables
│       ├── pages/              # Páginas por ruta
│       ├── store/              # Estado global (Zustand)
│       └── hooks/              # Custom hooks
├── docs/                       # Documentación y Postman
├── .github/workflows/          # CI/CD GitHub Actions
├── docker-compose.yml          # Servicios de desarrollo
└── pyproject.toml              # Configuración de ruff y coverage
```

---

## CI/CD

Cada push a `main` o `develop` ejecuta automáticamente:

1. **Backend**: lint con ruff → tests con coverage → reporte en Codecov
2. **Frontend**: TypeScript check → ESLint → tests Vitest → build de producción

Los workflows están en `.github/workflows/`.
