
# 🎭 Nariño Cultura.

## Plataforma cultural para artistas, eventos y comercialización digital en Nariño

![React](https://img.shields.io/badge/React-Frontend-blue)
![Vite](https://img.shields.io/badge/Vite-Build-purple)
![Django](https://img.shields.io/badge/Django-Backend-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED)
![JWT](https://img.shields.io/badge/Auth-JWT-orange)

---

# 📌 Descripción

**Nariño Cultura** es una plataforma web desarrollada como proyecto de grado orientada a fortalecer el ecosistema artístico y cultural del departamento de Nariño mediante herramientas digitales, inteligencia artificial y automatización.

La plataforma permite:

- Gestión de artistas y perfiles culturales.
- Publicación y comercialización de obras.
- Marketplace cultural.
- Subastas en tiempo real.
- Gestión de eventos culturales.
- Automatización con n8n.
- Integración de inteligencia artificial.
- Sistema de autenticación seguro con JWT.

El sistema implementa una arquitectura cliente-servidor distribuida y desacoplada. :contentReference[oaicite:0]{index=0}

---

# 🏗️ Stack Tecnológico

| Capa | Tecnologías |
|---|---|
| Frontend | React + Vite + TypeScript + Zustand + React Query |
| Backend | Python + Django + Django REST Framework |
| Base de Datos | PostgreSQL |
| Tiempo Real | Django Channels + WebSockets |
| IA | FastAPI + LangChain + scikit-learn |
| Automatización | n8n |
| Pagos | Wompi API |
| Despliegue | Render + Vercel |
| Testing | Vitest + Postman |

Frontend construido con React + Vite para interfaces dinámicas y reutilizables. :contentReference[oaicite:1]{index=1}

---

# ⚙️ Tecnologías Frontend

El frontend implementa:

- React + Vite.
- TypeScript.
- Zustand para manejo de estado global. :contentReference[oaicite:2]{index=2}
- React Query para consumo de APIs.
- TailwindCSS.
- Testing con Vitest. :contentReference[oaicite:3]{index=3}
- Variables de entorno para API REST, WebSockets y servicios externos. :contentReference[oaicite:4]{index=4}

---

# 🔄 Arquitectura de Comunicación

```text
Frontend / Mobile
        │
        ▼
 Django REST API
        │
 ┌──────┼────────┐
 │      │        │
 ▼      ▼        ▼
DB   WebSockets  Servicios
 │                │
 ▼                ▼
PostgreSQL      IA / Emails / n8n
=======
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
>>>>>>> feature/backend-auth
```

---

<<<<<<< HEAD
# 🔐 Seguridad

- Autenticación JWT.
- Protección de rutas.
- Roles y permisos.
- Verificación de correo.
- Middleware personalizado.
- Gestión segura de tokens.
- Control de acceso basado en permisos.

---

# 📡 Endpoints Principales

## 🔑 Autenticación

```http
POST /auth/register/
POST /auth/login/
POST /auth/logout/
POST /auth/verify-email/
POST /auth/password-reset/
```

## 👨‍🎨 Artistas

```http
GET    /artists/
POST   /artists/
GET    /artists/{slug}/
PATCH  /artists/{slug}/
```

## 🖼️ Obras de Arte

```http
GET    /artworks/
POST   /artworks/
GET    /artworks/{id}/
```

## 🏷️ Subastas

```http
GET    /auctions/
POST   /auctions/
POST   /auctions/{id}/bid/
```

## 🛒 Marketplace

```http
GET    /marketplace/cart/
POST   /marketplace/cart/items/
```

---

# 📂 Arquitectura Backend

```bash
apps/
├── artists/
├── artworks/
├── auctions/
├── marketplace/
├── notifications/
├── events/
└── users/

services/
├── ai_service.py
├── email_service.py
├── notification_service.py
└── payment_service.py
```

---

# ⚡ Instalación

## Clonar repositorio

```bash
git clone https://github.com/tu-usuario/narino-cultura.git
cd narino-cultura
```

## Crear entorno virtual

```bash
python -m venv venv
```

### Linux / macOS

```bash
source venv/bin/activate
```

### Windows

```bash
venv\Scripts\activate
```

## Instalar dependencias

```bash
pip install -r requirements.txt
```

## Variables de entorno

```env
DEBUG=True
SECRET_KEY=your_secret_key
DATABASE_URL=postgresql://user:password@localhost:5432/narinocultura
JWT_SECRET_KEY=jwt_secret
```

## Migraciones

```bash
python manage.py migrate
```

## Ejecutar servidor

```bash
python manage.py runserver
```

Servidor:

```bash
http://127.0.0.1:8000/
```

---

# 🐳 Docker

```bash
docker-compose up --build
```

---

# 🔄 WebSockets

El sistema utiliza Django Channels para:

- Subastas en tiempo real.
- Comunicación bidireccional.
- Eventos dinámicos.

```python
ASGI_APPLICATION = 'config.asgi.application'
```

---

# 📬 Sistema de Correos

Plantillas disponibles:

```text
templates/emails/
├── reset_password.html
├── verify_email.html
└── welcome.html
```

El sistema implementa correos automáticos para:

- Verificación de cuenta.
- Recuperación de contraseña.
- Bienvenida automática. :contentReference[oaicite:5]{index=5}

---

# 🧪 Testing

```bash
python manage.py test
```

Frontend con pruebas utilizando Vitest y Testing Library. :contentReference[oaicite:6]{index=6}

---

# 🤖 Inteligencia Artificial

La plataforma integra servicios de IA para:

- Generación automática de descripciones.
- Recomendaciones culturales.
- Chatbot cultural.
- Automatización inteligente. :contentReference[oaicite:7]{index=7}

---

# ⚙️ Automatización con n8n

Flujos automatizados para:

- Notificaciones.
- Alertas de subastas.
- Confirmaciones de pago.
- Correos automáticos. :contentReference[oaicite:8]{index=8}

---

# 📊 Calidad del Software

Evaluación mediante:

- Google Lighthouse.
- Postman.
- Pruebas unitarias.
- Pruebas de integración.
- Testing frontend y backend. :contentReference[oaicite:9]{index=9}

---

# 📱 Compatibilidad

| Plataforma | Estado |
|---|---|
| Web | ✅ Disponible |
| Android | ✅ En desarrollo |
| iOS | ❌ No implementado |

---

# 👨‍💻 Equipo de Desarrollo

- Juan Manuel Matabanchoy Cabrera
- Johan David Delgado Delgado
- Valery Nickol Rosero Molina

**Universidad Cooperativa de Colombia**  
Ingeniería de Software  
San Juan de Pasto – Colombia

---

# 📌 Estado Actual

```diff
+ API REST funcional
+ Sistema JWT implementado
+ Marketplace operativo
+ Subastas en tiempo real
+ Integración IA
+ Automatización n8n
- Aplicación iOS
=======
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
>>>>>>> feature/backend-auth
```

---

<<<<<<< HEAD
# 📝 Licencia

Proyecto desarrollado con fines académicos y educativos.

---

# ⭐ Recomendaciones

- Dale una estrella ⭐ al repositorio.
- Reporta errores o sugerencias.
- Contribuye con mejoras.

---

# 🙌 Agradecimientos

A la comunidad artística y cultural de Nariño por inspirar el desarrollo de soluciones tecnológicas orientadas al fortalecimiento del patrimonio cultural regional.

=======
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
>>>>>>> feature/backend-auth
