# Nariño Cultura

**Plataforma digital para la gestión, difusión y comercialización del ecosistema artístico de Nariño, Colombia.**

Proyecto de grado de Ingeniería de Software · Universidad Cooperativa de Colombia, campus Pasto · en colaboración con Corpocarnaval.

![Backend CI](https://github.com/JohanDsito/NARINO_CULTURA/actions/workflows/backend-ci.yml/badge.svg)
![Django](https://img.shields.io/badge/Django-5.1-0C4B33)
![React](https://img.shields.io/badge/React-19-61DAFB)
![Flutter](https://img.shields.io/badge/Flutter-Android-02569B)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Railway-336791)

---

## Qué hace

Reúne en un solo lugar a artistas, artesanos, músicos y gestores culturales con el público:

- **Perfiles** de artistas y músicos, con seguidores y reseñas.
- **Catálogo y venta directa** de obras, con pago en línea por **Wompi**.
- **Subastas en tiempo real** (WebSocket), con cierre automático y orden de pago para el ganador.
- **Agenda cultural**: eventos con moderación, inscripción y extracción de datos desde flyers con IA.
- **Descubrimiento musical** en lenguaje natural y un asistente conversacional.
- **Notificaciones** por correo y dentro de la plataforma.
- **Panel de administración**: moderación, usuarios, transacciones y métricas.

## Arquitectura

```
                 ┌──────────────┐   ┌──────────────────┐
                 │ Web (React)  │   │ App (Flutter)    │
                 └──────┬───────┘   └────────┬─────────┘
                        │  HTTPS (REST + JWT) · WebSocket
                        ▼
┌───────────────────────────────────────────────────────────┐
│ Backend · Django REST Framework + Channels (Daphne)       │
│   api/v1/…   ws/auctions/{id}/                            │
└──────┬───────────────┬──────────────┬─────────────────────┘
       │               │              │
  PostgreSQL         Redis      Worker Celery + Beat ──► Resend (correos)
                 (caché, colas,   (cierre de subastas,
                  canales WS)      vencimiento de órdenes,
                                   envío de notificaciones)

Servicios externos: Wompi (pagos) · Cloudinary (archivos) · Microservicio de IA (FastAPI + Gemini)
```

| Capa | Tecnología |
|---|---|
| Backend | Django 5.1, Django REST Framework 3.15, SimpleJWT, Channels 4.1 / Daphne, drf-spectacular (OpenAPI) |
| Tareas asíncronas | Celery 5.4 + Beat sobre Redis |
| Base de datos | PostgreSQL (producción) · SQLite en memoria (pruebas) |
| Web | React 19, TypeScript, Vite, Tailwind CSS, TanStack Query, Zustand |
| Móvil | Flutter (Android), Riverpod, Dio, en la rama `mobile-Valery` |
| IA | Microservicio FastAPI con Google Gemini y reglas de respaldo |
| Integraciones | Wompi (pagos), Resend (correo), Cloudinary (multimedia) |
| Despliegue | Railway: servicios `web`, `worker`, PostgreSQL y Redis |

## Estructura del repositorio

```
NARINO_CULTURA/
├── Backend/
│   ├── narinocultura_backend/   # Proyecto Django
│   │   ├── apps/                # users, artists, artworks, marketplace, auctions,
│   │   │                        # payments, events, musicians, music_discovery,
│   │   │                        # notifications, administration, system
│   │   ├── services/            # Lógica de negocio (subastas, pagos, notificaciones…)
│   │   ├── config/              # settings/{base,production,development,test}.py, celery, asgi
│   │   ├── templates/emails/    # Plantillas de correo
│   │   └── tests/               # Factories y utilidades de prueba
│   ├── ai_service/              # Microservicio de IA (FastAPI)
│   ├── Dockerfile · Procfile    # Despliegue en Railway
│   ├── requirements.txt         # Dependencias de producción
│   └── requirements-dev.txt     # Producción + herramientas de prueba (CI y local)
├── Front/Narino_Front/          # Aplicación web (React + Vite)
├── docs/                        # Documentación (ver docs/README.md)
└── .github/workflows/           # Integración continua del backend
```

## Ejecutar el backend en local

Requisitos: Python 3.12. PostgreSQL y Redis son opcionales en desarrollo.

```bash
cd Backend/narinocultura_backend
python -m venv venv
venv\Scripts\activate          # Windows  (Linux/macOS: source venv/bin/activate)
pip install -r ../requirements-dev.txt
cp ../.env.example ../.env     # y completa las variables
python manage.py migrate
python manage.py runserver
```

- API: `http://localhost:8000/api/v1/`
- Documentación interactiva (Swagger): `http://localhost:8000/api/docs/`
- Sin `REDIS_URL`, las tareas de Celery se ejecutan en el mismo proceso.

### Pruebas

```bash
cd Backend/narinocultura_backend
DJANGO_SETTINGS_MODULE=config.settings.test python manage.py test apps
```

Las pruebas usan SQLite en memoria y no llaman a servicios externos. El CI (`.github/workflows/backend-ci.yml`) las ejecuta en cada pull request, exige **80 % de cobertura** y que `ruff` no reporte ninguna advertencia en el backend. Para revisarlo en local:

```bash
ruff check --config ../pyproject.toml .
```

## Variables de entorno principales

| Grupo | Variables |
|---|---|
| Django | `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `CORS_ALLOWED_ORIGINS`, `CSRF_TRUSTED_ORIGINS`, `FRONTEND_BASE_URL`, `API_BASE_URL` |
| Datos | `DB_ENGINE`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `REDIS_URL` |
| Pagos (Wompi) | `WOMPI_BASE_URL`, `WOMPI_PUBLIC_KEY`, `WOMPI_PRIVATE_KEY`, `WOMPI_INTEGRITY_KEY`, `WOMPI_EVENTS_SECRET` |
| Correo | `RESEND_API_KEY`, `RESEND_FROM_EMAIL`, `EMAIL_FROM_NAME` |
| Archivos | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` |
| IA | `AI_SERVICE_URL` |
| Subastas | `AUCTION_PAYMENT_HOURS` (plazo de pago del ganador, 48 h por defecto) |
| Administrador inicial | `ADMIN_EMAIL`, `ADMIN_PASSWORD` (solo si el administrador no existe) |

En producción el servidor no arranca sin `SECRET_KEY`, `ALLOWED_HOSTS` y `WOMPI_EVENTS_SECRET`.

## Despliegue

El backend se despliega en **Railway** desde la rama `main` (directorio raíz `/Backend`):

| Servicio | Proceso |
|---|---|
| `web` | `migrate` → `create_admin` → Daphne (HTTP + WebSocket) |
| `worker` | `celery -A config.celery worker --beat` |
| PostgreSQL · Redis | Servicios administrados de Railway |

Cada fusión a `main` despliega automáticamente. Los webhooks de Wompi llegan a `/api/v1/payments/wompi-webhook/`.

## Documentación

Toda la documentación está en [`docs/`](docs/README.md): el documento técnico del proyecto, la colección de Postman para la prueba de punta a punta y el material histórico.

## Equipo

| Integrante | Rol |
|---|---|
| Johan David Delgado Delgado | Product Owner · Backend, pagos, IA, despliegue |
| Valery Nickol Rosero Molina | Scrum Master · Aplicación móvil (Flutter) |
| Juan Manuel Matabanchoy Cabrera | Desarrollador · Aplicación web (React) |

Universidad Cooperativa de Colombia · Facultad de Ingeniería · San Juan de Pasto, 2026.
