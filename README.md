# 🎭 Nariño Cultura

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
```

---

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
```

---

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

