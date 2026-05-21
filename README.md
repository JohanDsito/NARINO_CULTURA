
# 🎭 Nariño Cultura

## Plataforma integral para la gestión, difusión y comercialización del ecosistema artístico de Nariño

![Python](https://img.shields.io/badge/Python-3.11+-blue)
![Django](https://img.shields.io/badge/Django-5.x-green)
![Django REST Framework](https://img.shields.io/badge/DRF-REST-red)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED)
![JWT](https://img.shields.io/badge/Auth-JWT-orange)
![WebSockets](https://img.shields.io/badge/Realtime-WebSockets-purple)
![Status](https://img.shields.io/badge/Status-En%20Desarrollo-success)
![License](https://img.shields.io/badge/License-Academic-lightgrey)

---

# 📌 Descripción del Proyecto

**Nariño Cultura** es una plataforma digital integral orientada a fortalecer el ecosistema cultural y artístico del departamento de Nariño, Colombia.

El proyecto busca brindar herramientas tecnológicas modernas para:

- Promover la visibilidad de artistas y artesanos.
- Facilitar la comercialización de obras y servicios culturales.
- Impulsar el turismo cultural regional.
- Centralizar eventos y actividades culturales.
- Integrar procesos de automatización e inteligencia artificial.
- Fortalecer la economía creativa mediante soluciones digitales.

La plataforma está enfocada especialmente en artistas, artesanos y actores culturales relacionados con el **Carnaval de Negros y Blancos**, patrimonio cultural reconocido internacionalmente.

---

# 🎯 Objetivo General

Desarrollar una plataforma web integral que promueva la visibilidad, sostenibilidad económica y colaboración entre artistas, músicos, artesanos y gestores culturales de Nariño mediante herramientas tecnológicas, inteligencia artificial, automatización de procesos y un marketplace cultural.

---

# 🚀 Características Principales

## 🔐 Sistema de Autenticación

- Registro y login con JWT.
- Verificación de correo electrónico.
- Recuperación y cambio de contraseña.
- Roles y permisos personalizados.
- Gestión de sesiones seguras.

## 👨‍🎨 Gestión de Artistas

- Creación de perfiles profesionales.
- Información artística personalizada.
- Redes sociales integradas.
- Seguimiento de artistas.
- Perfiles públicos y privados.

## 🖼️ Gestión de Obras de Arte

- Publicación de obras.
- Categorías artísticas.
- Gestión de imágenes.
- Información técnica de obras.
- Actualización y administración de contenido.

## 🛒 Marketplace Cultural

- Carrito de compras.
- Gestión de órdenes.
- Favoritos.
- Compra y venta de obras.
- Flujo comercial digital.

## 🏷️ Sistema de Subastas

- Subastas en tiempo real.
- Gestión de pujas.
- WebSockets con Django Channels.
- Actualización dinámica de ofertas.
- Control de tiempos de subasta.

## 📅 Gestión de Eventos

- Calendario cultural.
- Eventos artísticos.
- Actividades culturales.
- Organización de eventos.
- Difusión cultural.

## 🤖 Inteligencia Artificial

- Generación automática de descripciones.
- Personalización cultural.
- Recomendaciones inteligentes.
- Automatización de contenido.

## 🔔 Sistema de Notificaciones

- Correos automáticos.
- Notificaciones del sistema.
- Recordatorios.
- Confirmaciones.

## ⚙️ Automatización de Procesos

- Integración con n8n.
- Flujos automatizados.
- Orquestación de procesos.
- Integración de servicios.

---

# 🏗️ Arquitectura del Proyecto

El proyecto implementa una arquitectura modular basada en servicios y aplicaciones desacopladas utilizando Django y Django REST Framework.

## 📂 Estructura General del Backend

```bash
narinocultura_backend/
│
├── apps/
│   ├── administration/
│   ├── artists/
│   ├── artworks/
│   ├── auctions/
│   ├── events/
│   ├── marketplace/
│   ├── notifications/
│   ├── payments/
│   ├── system/
│   └── users/
│
├── config/
│   ├── settings/
│   ├── urls.py
│   ├── asgi.py
│   └── routing.py
│
├── services/
│   ├── ai_service.py
│   ├── auction_service.py
│   ├── email_service.py
│   ├── event_service.py
│   ├── marketplace_service.py
│   ├── notification_service.py
│   └── payment_service.py
│
├── templates/
├── utils/
├── docs/
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```

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

# 🔐 Seguridad Implementada

- Autenticación JWT.
- Protección de rutas.
- Roles y permisos.
- Verificación de email.
- Middleware personalizado.
- Validaciones de entrada.
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
POST /auth/password-reset/confirm/
```

## 👨‍🎨 Artistas

```http
GET    /artists/
POST   /artists/
GET    /artists/{slug}/
PATCH  /artists/{slug}/
POST   /artists/{slug}/follow/
```

## 🖼️ Obras de Arte

```http
GET    /artworks/
POST   /artworks/
GET    /artworks/{id}/
PATCH  /artworks/{id}/
POST   /artworks/{id}/ai-enhance/
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
GET    /marketplace/favorites/
POST   /marketplace/favorites/
```

---

# ⚡ Instalación del Proyecto

## 1️⃣ Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/narino-cultura.git
cd narino-cultura
```

---

## 2️⃣ Crear entorno virtual

```bash
python -m venv venv
```

### Linux / macOS

```bash
source venv/bin/activate
```

### Windows

```bash
venv\\Scripts\\activate
```

---

## 3️⃣ Instalar dependencias

```bash
pip install -r requirements.txt
```

---

## 4️⃣ Configurar variables de entorno

Crear archivo `.env`

```env
DEBUG=True
SECRET_KEY=your_secret_key
DATABASE_URL=postgresql://user:password@localhost:5432/narinocultura
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_HOST_USER=example@example.com
EMAIL_HOST_PASSWORD=password
JWT_SECRET_KEY=jwt_secret
```

---

## 5️⃣ Ejecutar migraciones

```bash
python manage.py migrate
```

---

## 6️⃣ Crear superusuario

```bash
python manage.py createsuperuser
```

---

## 7️⃣ Ejecutar servidor

```bash
python manage.py runserver
```

Servidor disponible en:

```bash
http://127.0.0.1:8000/
```

---

# 🐳 Ejecución con Docker

## Construcción y ejecución

```bash
docker-compose up --build
```

---

# 🧪 Testing

El proyecto incluye pruebas automatizadas para módulos críticos.

## Ejecutar tests

```bash
python manage.py test
```

## Módulos con pruebas

- Users
- Payments
- Auctions

---

# 📬 Sistema de Correos

La plataforma implementa:

- Verificación de correo.
- Bienvenida automática.
- Recuperación de contraseña.
- Notificaciones automatizadas.

Plantillas disponibles:

```text
templates/emails/
├── reset_password.html
├── verify_email.html
└── welcome.html
```

---

# 🔄 WebSockets y Tiempo Real

El sistema utiliza Django Channels para:

- Actualización de subastas.
- Pujas en tiempo real.
- Comunicación bidireccional.
- Eventos en vivo.

Configuración principal:

```python
ASGI_APPLICATION = 'config.asgi.application'
```

---

# 📁 Documentación Técnica

El proyecto incluye documentación adicional:

```text
docs/
├── BREVO-SETUP.md
├── CAMBIOS-BREVO.md
├── n8n/
└── postman/
```

---

# 📮 Colecciones Postman

Incluye:

- Colecciones de endpoints.
- Variables de entorno.
- Payloads de ejemplo.
- Guías rápidas.
- Scripts automatizados.

---

# 📊 Calidad del Software

La plataforma fue evaluada utilizando:

- Google Lighthouse.
- Pruebas funcionales.
- Pruebas de integración.
- Validaciones de usabilidad.
- Métricas de rendimiento.

## Aspectos evaluados

- Rendimiento.
- Accesibilidad.
- SEO.
- Buenas prácticas.
- Experiencia de usuario.

---

# 📱 Compatibilidad

| Plataforma | Estado |
|---|---|
| Web | ✅ Disponible |
| Android | ✅ En desarrollo |
| iOS | ❌ No implementado |

---

# 🤖 Inteligencia Artificial Integrada

El sistema incorpora servicios de IA para:

- Mejorar descripciones de obras.
- Automatizar contenido.
- Personalizar experiencias culturales.
- Optimizar interacción con usuarios.

Archivo principal:

```text
services/ai_service.py
```

---

# ⚙️ Automatización con n8n

El proyecto integra automatizaciones mediante n8n para:

- Flujos de autenticación.
- Correos automáticos.
- Integración de servicios.
- Orquestación de eventos.

Configuraciones disponibles:

```text
docs/n8n/
```

---

# 📈 Futuras Mejoras

- Aplicación móvil iOS.
- Sistema avanzado de recomendaciones IA.
- Integración con pasarelas de pago internacionales.
- Analítica cultural avanzada.
- Streaming de eventos culturales.
- Dashboard institucional.
- Sistema avanzado de turismo cultural.

---

# 👨‍💻 Equipo de Desarrollo

## Autores

- Juan Manuel Matabanchoy Cabrera
- Johan David Delgado Delgado
- Valery Nickol Rosero Molina

## Universidad

**Universidad Cooperativa de Colombia**  
Facultad de Ingeniería  
Ingeniería de Software  
San Juan de Pasto – Colombia

---

# 📚 Contexto Académico

Proyecto de grado desarrollado como propuesta tecnológica orientada a fortalecer el ecosistema artístico y cultural del departamento de Nariño mediante soluciones digitales innovadoras.

---

# 🌎 Impacto del Proyecto

## Social

- Democratización del acceso cultural.
- Mayor visibilidad para artistas.
- Fortalecimiento de identidad regional.

## Económico

- Impulso a la economía creativa.
- Nuevos canales de comercialización.
- Conexión entre turismo y cultura.

## Tecnológico

- Integración de IA.
- Arquitectura escalable.
- Automatización de procesos.

---

# 📌 Estado Actual

```diff
+ Backend principal implementado
+ API REST funcional
+ Sistema de autenticación completo
+ Marketplace funcional
+ Subastas en tiempo real
+ Integración con IA
+ Automatización con n8n
- Aplicación móvil finalizada
- Integraciones externas avanzadas
```

---

# 📝 Licencia

Este proyecto fue desarrollado con fines académicos y educativos.

---

# ⭐ Recomendaciones

Si este proyecto te resulta interesante:

- Dale una estrella ⭐ al repositorio.
- Comparte el proyecto.
- Contribuye con mejoras.
- Reporta errores o sugerencias.

---

# 📬 Contacto

Para dudas, mejoras o colaboración:

📧 Contacto académico y de desarrollo disponible mediante GitHub.

---

# 🙌 Agradecimientos

A la comunidad artística y cultural de Nariño por inspirar el desarrollo de soluciones tecnológicas orientadas al fortalecimiento de la identidad regional y la preservación del patrimonio cultural.
````
