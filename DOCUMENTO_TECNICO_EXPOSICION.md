# Nariño Cultura — Documento Técnico para Exposición de Grado

**Proyecto de Grado:** Ingeniería de Software  
**Institución:** Universidad Cooperativa de Colombia (UCC)  
**Proyecto:** Ecosistema digital de marketplace y cultura artística para el departamento de Nariño, Colombia  
**Colaboración:** Corpocarnaval  

---

## 1. Descripción General del Proyecto

**Nariño Cultura** es una plataforma web integral que conecta a artistas plásticos, músicos y gestores culturales de la región con compradores, patrocinadores y el público general. Su propósito es digitalizar y democratizar el acceso al arte y la cultura nariñense mediante un ecosistema que integra:

- Exhibición y venta de obras de arte originales
- Subastas en tiempo real para piezas de alto valor
- Descubrimiento musical mediante lenguaje natural e inteligencia artificial
- Organización y registro de eventos culturales
- Panel administrativo para moderación y auditoría

El proyecto tiene una arquitectura **cliente-servidor completamente desacoplada**, donde el backend expone una API REST que el frontend consume, y múltiples servicios externos se integran como componentes especializados.

---

## 2. Arquitectura General del Sistema

### 2.1 Modelo de Capas

La plataforma sigue una arquitectura **multicapa** con responsabilidades bien definidas:

```
┌─────────────────────────────────────────────┐
│         Capa de Presentación (Frontend)      │
│   React 19 + TypeScript + Tailwind CSS       │
│   SPA — corre en el navegador del usuario    │
└────────────────────┬────────────────────────┘
                     │ HTTP REST + WebSockets
┌────────────────────▼────────────────────────┐
│         Capa de Aplicación (Backend)         │
│   Django 5.1.7 + Django REST Framework      │
│   Toda la lógica de negocio y seguridad      │
└────┬──────────┬──────────┬──────────────────┘
     │          │          │
┌────▼──┐  ┌───▼───┐  ┌───▼──────────────────┐
│ Post- │  │ Redis │  │ Servicios externos    │
│ greSQL│  │ Cache │  │ (Cloudinary, Wompi,  │
│       │  │ +Colas│  │  N8N, Resend, IA)    │
└───────┘  └───────┘  └──────────────────────┘
```

**Capa de Presentación:** La aplicación React corre íntegramente en el navegador. No tiene acceso directo a la base de datos ni a servicios externos — toda interacción pasa por el backend.

**Capa de Aplicación:** Django concentra toda la lógica de negocio, validaciones, reglas de autorización y orquestación de servicios. Es el único punto de entrada para operaciones sobre datos.

**Capa de Infraestructura:** Servicios de soporte como la base de datos relacional, caché en memoria, almacenamiento de archivos en la nube, sistema de colas y servicios externos especializados.

### 2.2 Principios Arquitectónicos

El diseño sigue el principio de **separación de responsabilidades (SoC)**: cada componente tiene una única razón para cambiar. Esto se traduce en:

- El frontend solo presenta datos y captura acciones del usuario
- El backend valida, persiste y coordina
- Los servicios externos manejan dominios específicos que no son competencia central del sistema (pagos, email, CDN, IA)

Adicionalmente se aplican los principios del **12-Factor App**: configuración por variables de entorno, logs a stdout, procesos sin estado (stateless), respaldo de servicios como recursos adjuntos.

---

## 3. Backend — Django REST Framework

### 3.1 Estructura Modular por Dominio

El backend organiza el código en **aplicaciones Django**, donde cada una encapsula un dominio de negocio completo con sus propios modelos, serializers, vistas, URLs y tests. Esta es la lista de módulos y su responsabilidad:

| Módulo | Responsabilidad |
|--------|----------------|
| `users` | Autenticación, registro, verificación de email, JWT, roles de usuario |
| `artists` | Perfiles de artistas plásticos, seguidores, disciplinas artísticas |
| `artworks` | Catálogo de obras, categorías, galería de imágenes, moderación |
| `marketplace` | Carrito de compras, favoritos, órdenes, proceso de checkout |
| `auctions` | Subastas en tiempo real, pujas, cierre automático |
| `payments` | Integración Wompi, transacciones, webhooks de pago |
| `events` | Eventos culturales, registro de asistentes, extracción IA de afiches |
| `notifications` | Registro histórico de notificaciones enviadas al sistema |
| `administration` | Panel admin: gestión de usuarios, moderación de obras, métricas |
| `system` | Health check, middleware de auditoría de actividad |
| `musicians` | Perfiles de músicos y bandas, géneros, obras musicales |
| `music_discovery` | Descubrimiento musical por lenguaje natural, chat con IA |

Esta modularidad tiene varias ventajas: cada dominio evoluciona de forma independiente, los tests se escriben por módulo de forma aislada, y el código es fácil de ubicar y mantener. En una escala mayor, cada módulo podría extraerse como un microservicio independiente.

### 3.2 Patrones de Diseño Aplicados

#### ViewSet Pattern
DRF organiza los endpoints en **ViewSets** que agrupan las operaciones CRUD (Create, Read, Update, Delete) sobre un mismo recurso bajo una sola clase. Esto reduce la duplicación y estandariza el comportamiento. Por ejemplo, `ArtworkViewSet` maneja `GET /artworks/`, `POST /artworks/`, `GET /artworks/{id}/`, `PATCH /artworks/{id}/` y `DELETE /artworks/{id}/` con una sola clase.

#### Serializer Pattern
Los **serializers** son la capa de transformación entre los modelos de base de datos y las representaciones JSON de la API. Tienen dos responsabilidades:

1. **Serialización (salida):** convertir objetos Python a JSON, componer campos anidados (por ejemplo, incluir el nombre de la categoría junto a su ID).
2. **Deserialización y validación (entrada):** convertir JSON entrante a objetos Python validados, lanzar errores descriptivos si los datos no cumplen las reglas.

Se separa el serializer de lectura del de escritura cuando la representación difiere. Por ejemplo, la imagen de una obra se sube como archivo binario (`multipart/form-data`) pero se devuelve como URL pública.

#### Service Layer Pattern
La lógica compleja que involucra múltiples modelos se extrae a **clases de servicio** independientes del framework HTTP:

- `AuctionService`: crear subasta, registrar puja con locking, cerrar subasta y declarar ganador
- `EmailService`: enviar emails con cadena de prioridad (Resend → SMTP fallback)
- `NotificationService`: registrar y disparar webhooks a N8N
- `AIService`: delegar a microservicio externo, o Gemini/OpenAI, o reglas locales (fallback en cascada)
- `MarketplaceService`: validaciones de checkout, transacciones atómicas de compra

Las vistas solo orquestan: reciben la petición, llaman al servicio, devuelven la respuesta. Las reglas de negocio viven en los servicios, no en las vistas.

#### Permission Layer
Los permisos se definen como clases reutilizables y se aplican declarativamente a cada vista:

- `IsAdmin`: solo usuarios con rol ADMINISTRADOR
- `IsArtist`: solo usuarios con rol ARTISTA
- `IsOwnerOrReadOnly`: el dueño puede modificar, cualquiera puede leer
- `IsArtworkOwnerOrReadOnly`: el artista dueño de la obra puede editarla

Esto desacopla la lógica de autorización de la lógica de negocio. Cambiar quién puede acceder a un endpoint no requiere tocar las vistas.

#### Strategy Pattern (Inteligencia Artificial)
El servicio de IA implementa una **cadena de estrategias con fallback**:

1. Intentar microservicio FastAPI externo
2. Si no disponible → intentar Gemini API (Google)
3. Si no disponible → sistema de reglas basadas en palabras clave

El componente que llama al servicio no necesita saber cuál estrategia se usó. Esto garantiza disponibilidad del feature incluso cuando los servicios externos fallan.

### 3.3 Autenticación y Seguridad

#### JSON Web Tokens (JWT)
El sistema usa autenticación **stateless** mediante JWT con `django-rest-framework-simplejwt`:

- **Token de acceso (access token):** vida útil de 30 minutos. Se envía en el header `Authorization: Bearer <token>` en cada petición protegida.
- **Token de refresco (refresh token):** vida útil de 7 días. Se usa únicamente para obtener nuevos tokens de acceso. Al usarse, se rota automáticamente (se invalida el anterior y se emite uno nuevo).
- **Blacklist:** al hacer logout, el refresh token se agrega a una lista negra en base de datos, imposibilitando su uso futuro aunque no haya expirado.

Este diseño balancea seguridad (tokens de corta duración) y usabilidad (el usuario no se desconecta cada 30 minutos).

#### Control de Acceso por Roles (RBAC)
Cuatro roles definen qué puede hacer cada tipo de usuario:

| Rol | Capacidades principales |
|-----|------------------------|
| `COMPRADOR` | Ver obras, comprar, pujar, registrarse en eventos |
| `ARTISTA` | Todo lo anterior + crear/editar sus obras, crear subastas |
| `GESTOR_CULTURAL` | Crear y gestionar eventos culturales |
| `ADMINISTRADOR` | Acceso total: moderar obras, gestionar usuarios, ver métricas |

El rol `GESTOR_CULTURAL` **no puede auto-asignarse** en el registro. Solo un administrador puede crearlo vía endpoint protegido, evitando escalada de privilegios.

#### Hashing de Contraseñas
Se usa **Argon2**, ganador del Password Hashing Competition 2015, considerado el algoritmo de hashing de contraseñas más seguro actualmente disponible. Es resistente a ataques de hardware especializado (GPUs/ASICs).

#### Rate Limiting (Limitación de Peticiones)
Protección contra abuso mediante throttling progresivo:

- Usuarios anónimos: 200 peticiones/hora
- Usuarios autenticados: 2000 peticiones/hora
- Endpoint de registro: 5 intentos/minuto
- Endpoint de reset de contraseña: 3 intentos/hora

#### Verificación Criptográfica de Webhooks
La integración con Wompi (pagos) verifica cada notificación entrante mediante **firma HMAC-SHA256**. El servidor calcula la firma esperada con la clave secreta y la compara con la que envía Wompi. Si no coinciden, se rechaza la notificación — esto previene que un atacante forje notificaciones de pago.

### 3.4 Comunicación en Tiempo Real (WebSockets)

Las subastas requieren que múltiples usuarios vean las pujas al instante sin recargar la página. Esto se implementa con **Django Channels** que extiende Django del protocolo HTTP síncrono al protocolo ASGI (Asynchronous Server Gateway Interface).

**Flujo técnico:**
1. El navegador establece una conexión WebSocket a `/ws/auctions/{id}/`
2. El servidor envía el estado actual de la subasta (precio actual, historial de pujas)
3. Cuando un usuario puja, el servidor persiste la puja en PostgreSQL
4. El servidor transmite (broadcast) la nueva puja a **todos** los usuarios conectados a esa sala
5. El frontend actualiza el precio en pantalla en tiempo real

**Canal de Redis como bus de mensajes:** Cuando hay múltiples instancias del servidor (escalado horizontal), Redis actúa como intermediario. El servidor A puede enviar un mensaje que todos los clientes conectados al servidor B también reciban — Redis garantiza que el broadcast es global, no solo local a un proceso.

**Locking pesimista para integridad:** Cuando dos usuarios pujan simultáneamente, el servidor usa `SELECT FOR UPDATE` en PostgreSQL. Solo un proceso puede "bloquear" la fila de la subasta a la vez — el segundo espera hasta que el primero libere el lock. Esto garantiza que nunca habrá dos pujas aceptadas por el mismo monto.

### 3.5 Procesamiento Asíncrono (Celery)

Algunas operaciones no deben ejecutarse durante el ciclo petición-respuesta HTTP porque son lentas o pueden fallar sin afectar al usuario:

| Tarea | Mecanismo | Frecuencia |
|-------|-----------|-----------|
| Cerrar subastas vencidas | Celery Beat (cron) | Cada 60 segundos |
| Envío de notificaciones | Cola Celery | En demanda |
| Emails de confirmación | Cola Celery | En demanda |

**Redis como broker:** Django encola una tarea escribiéndola en Redis. Los **workers de Celery** (procesos separados) leen la cola y ejecutan las tareas de forma independiente. El servidor principal responde al usuario inmediatamente sin esperar que la tarea termine.

**Celery Beat** es el planificador: ejecuta tareas periódicas según una agenda (similar a cron en Unix). El cierre de subastas se verifica cada minuto de forma automática.

### 3.6 Caché con Redis

Redis se usa también como caché para reducir queries innecesarios a PostgreSQL:

- **Categorías de obras:** se cachean por 1 hora. En lugar de consultar PostgreSQL en cada petición de catálogo, se sirven desde la memoria de Redis.
- **Datos de configuración:** información que cambia raramente se guarda en caché con TTL (Time To Live) apropiado.

Si Redis no está disponible (por ejemplo, en un entorno de desarrollo sin Docker), el sistema degrada gracefully a caché en memoria local del proceso — pierde rendimiento pero no se cae.

### 3.7 Almacenamiento de Archivos en la Nube

El proveedor de hosting (Railway) tiene un filesystem **efímero**: los archivos subidos se pierden al redeployar o reiniciar el servidor. Para solucionar esto se integra **Cloudinary**:

- Cuando un artista sube la foto de su obra, Django transfiere el archivo directamente a Cloudinary vía su SDK
- Cloudinary devuelve una URL permanente y optimizada que se almacena en PostgreSQL
- Las imágenes se sirven desde el CDN de Cloudinary al usuario más cercano geográficamente
- La configuración es **condicional**: si las credenciales de Cloudinary están en las variables de entorno, Django usa ese backend; de lo contrario usa el filesystem local (útil en desarrollo)

---

## 4. Frontend — React + TypeScript

### 4.1 Single-Page Application (SPA)

La aplicación frontend es un **SPA**: el servidor entrega una sola página HTML con el bundle JavaScript al primer acceso. Toda la navegación posterior ocurre en el cliente sin recargar la página — React Router intercepta los cambios de URL y renderiza los componentes correspondientes.

Este diseño tiene ventajas de experiencia de usuario (transiciones instantáneas, sin parpadeo) y arquitectónicas (el backend solo necesita ser una API, no generar HTML).

**Vite** es el bundler: compila TypeScript a JavaScript, maneja imports de módulos, genera bundles optimizados para producción con tree-shaking (elimina código no usado) y code-splitting (carga de componentes bajo demanda).

### 4.2 Gestión de Estado

El estado se divide en dos categorías con herramientas distintas según su naturaleza:

#### Estado del Servidor — TanStack Query
Datos que vienen de la API (obras, perfiles, eventos) son gestionados por **TanStack Query** (antes React Query). Esta librería maneja automáticamente:

- **Caché de respuestas:** una query ejecutada no se repite hasta que los datos expiren o se invaliden
- **Invalidación inteligente:** cuando el usuario crea una obra, el cache de la lista de obras se invalida automáticamente
- **Estados de carga y error:** cada query expone `isLoading`, `isError`, `data` sin código manual
- **Deduplicación:** si dos componentes piden los mismos datos simultáneamente, solo se hace una petición HTTP
- **Refetch automático:** al volver a la pestaña o reconectar la red, los datos se actualizan

#### Estado del Cliente — Zustand
Estado local de la sesión que no viene del servidor, gestionado por **Zustand** (store minimalista):

| Store | Contenido | Persistencia |
|-------|-----------|-------------|
| `authStore` | Usuario autenticado, tokens JWT | Memoria (sesión) |
| `cartStore` | Items del carrito | `localStorage` (persiste entre recargas) |
| `themeStore` | Tema claro/oscuro | `localStorage` (persiste entre recargas) |

### 4.3 Comunicación con el Backend

Toda comunicación HTTP usa **Axios** a través de una instancia centralizada con interceptores que automatizan tareas repetitivas:

**Interceptor de petición:**
- Agrega automáticamente el header `Authorization: Bearer <access_token>` a cada petición protegida
- El componente no necesita saber nada sobre tokens

**Interceptor de respuesta:**
- Detecta errores `401 Unauthorized` (token de acceso expirado)
- Ejecuta automáticamente el refresh del token en segundo plano
- Reintenta la petición original con el nuevo token
- El usuario nunca nota que su sesión se refrescó

Esta arquitectura centralizada significa que si en el futuro cambia el mecanismo de autenticación, solo se modifica el interceptor, no cientos de llamadas en toda la aplicación.

### 4.4 Validación de Formularios

Los formularios combinan dos librerías:

- **React Hook Form:** gestiona el estado del formulario minimizando re-renders. Solo se re-renderiza el campo que cambia, no todo el formulario.
- **Zod:** define esquemas de validación con tipos TypeScript derivados automáticamente. Las mismas reglas del esquema generan tanto la validación en runtime como los tipos estáticos del compilador.

Las validaciones corren en el cliente para dar feedback inmediato, pero el servidor **siempre revalida** los datos por seguridad — nunca se confía ciegamente en el cliente.

### 4.5 Sistema de Diseño con Tokens Semánticos

El sistema de diseño usa **variables CSS semánticas** definidas en `:root` para modo claro y `.dark` para modo oscuro. En lugar de usar colores directos (`#2D1B00`), los componentes usan tokens semánticos:

| Token | Propósito |
|-------|-----------|
| `bg-card` | Fondo de tarjetas y paneles |
| `text-foreground` | Texto principal de contenido |
| `text-muted` | Texto secundario y etiquetas |
| `border` | Bordes de contenedores |
| `bg-muted` | Superficies de menor énfasis |

La paleta de marca (`oro`, `tierra`, `selva`, `volcán`) refleja la identidad visual del departamento de Nariño. Al cambiar entre modo claro y oscuro, **todos los componentes se adaptan automáticamente** porque los tokens apuntan a diferentes valores CSS — sin lógica condicional en los componentes.

**Tailwind CSS** consume estas variables como utilidades (`bg-card`, `text-foreground`), combinando la ergonomía de clases utilitarias con la flexibilidad del sistema de tokens.

### 4.6 Enrutamiento y Protección de Rutas

React Router v6 organiza las rutas en tres grupos:

- **Rutas públicas:** accesibles sin autenticación (`/artworks`, `/events`, `/login`, `/register`)
- **Rutas protegidas:** requieren autenticación (`/checkout`, `/notifications`)
- **Rutas por rol:** requieren rol específico (`/admin/*` solo ADMINISTRADOR, `/dashboard/*` solo ARTISTA)

Los componentes `PrivateRoute` y `RoleRoute` verifican el estado del `authStore`. Si el usuario no cumple el requisito, se redirige al login o a una página de error de autorización.

El dashboard redirige automáticamente según el rol del usuario autenticado, evitando que un artista aterrice en el panel de administración.

---

## 5. Servicios Independientes e Integraciones

### 5.1 N8N — Automatización de Flujos de Trabajo

**N8N** es una plataforma open-source de automatización de flujos (similar a Zapier) desplegada como servicio independiente en Render. El backend Django envía **webhooks** (peticiones HTTP) a N8N cuando ocurren eventos de negocio.

**Flujo de automatización de subastas:**
```
Subasta cierra con ganador
    → Django llama a N8N webhook con datos
        → N8N envía email al ganador con instrucciones de pago
        → N8N envía email al artista con datos del comprador
        → N8N registra el evento en logs
```

**Arquitectura híbrida de emails:** Los emails críticos de autenticación (verificación de cuenta, reset de contraseña) van directamente desde Django vía SMTP, sin pasar por N8N. Esto garantiza entrega alta incluso si N8N no está disponible. N8N maneja los emails de negocio (eventos publicados, registros, subastas), donde un retraso pequeño es aceptable.

Esta separación sigue el principio de **alta cohesión y bajo acoplamiento**: N8N puede evolucionar, cambiar flujos o fallar sin afectar la autenticación del sistema.

### 5.2 Resend / SMTP — Email Transaccional

El servicio de email implementa una **cadena de prioridad**:

1. **Resend:** proveedor especializado de email transaccional con alta tasa de entrega. Los emails salen desde el dominio `narinocultura.uk`, lo que mejora la reputación del remitente y reduce la probabilidad de caer en spam.
2. **Brevo/SMTP:** fallback. Si Resend falla, Django usa SMTP estándar para garantizar que el email llega.

### 5.3 Wompi — Pasarela de Pago

**Wompi** es el proveedor de pagos colombiano (subsidiaria de Bancolombia) integrado para procesar pagos con tarjeta de crédito/débito, PSE y efectivo.

**Flujo de pago:**
```
1. Usuario en checkout
2. Backend genera firma HMAC-SHA256 con datos de la orden
3. Frontend renderiza el widget de Wompi con la firma
4. Usuario completa el pago en el widget de Wompi
5. Wompi notifica al backend via webhook POST /payments/wompi/webhook/
6. Backend verifica la firma del webhook (autenticidad)
7. Backend actualiza estado: Orden → PAGADA, Obra → VENDIDA
8. Backend dispara notificación de confirmación al comprador
```

El uso de firma criptográfica en ambos sentidos garantiza que:
- Wompi solo acepta peticiones de inicio de pago firmadas por nuestro servidor (no se puede manipular el monto desde el cliente)
- El servidor solo acepta notificaciones firmadas por Wompi (no se puede forjar una confirmación de pago)

Actualmente integrado en **modo sandbox** (pruebas). Para producción se requiere cuenta verificada con Wompi Colombia y credenciales de producción.

### 5.4 Cloudinary — CDN y Almacenamiento de Media

**Cloudinary** es el backend de almacenamiento de todas las imágenes de la plataforma. Sus características clave:

- **Persistencia garantizada:** las imágenes sobreviven cualquier redeploy del servidor
- **CDN global:** las imágenes se sirven desde el nodo geográficamente más cercano al usuario
- **Transformaciones automáticas:** se puede pedir versiones redimensionadas, recortadas o comprimidas de la misma imagen vía URL, sin procesar nada en el servidor
- **Gestión de assets:** dashboard de Cloudinary muestra todas las imágenes subidas, carpetas, uso de ancho de banda

La configuración es **condicional en Django**: el backend detecta si las credenciales de Cloudinary están definidas en las variables de entorno. En desarrollo sin credenciales, usa el filesystem local; en producción con credenciales, usa Cloudinary. Esta transparencia es posible gracias al patrón **Storage Backend** de Django.

### 5.5 Inteligencia Artificial

El sistema integra IA en tres funcionalidades distintas:

#### Chat Conversacional — Asistente Cultural
El endpoint `POST /api/v1/chat/` recibe un mensaje del usuario y responde en lenguaje natural. Accesible a usuarios anónimos (se identifica la sesión por IP) y autenticados.

El chatbot tiene **contexto del sistema** que lo instruye a ser un asistente cultural de Nariño: conoce la plataforma, sus funcionalidades, y puede responder preguntas sobre arte, música y eventos locales.

**Cadena de prioridad:**
1. Gemini API (Google) — modelo de lenguaje de última generación
2. Respuestas de fallback basadas en reglas si la API no está disponible

#### Descubrimiento Musical — Recomendaciones por Lenguaje Natural
El endpoint de recomendaciones convierte una consulta en texto ("bandas de jazz de Pasto que toquen en festivales") en **filtros estructurados** que se aplican sobre la base de datos de músicos. El resultado es una lista de músicos que coinciden con la intención del usuario, sin que este necesite conocer los filtros disponibles.

**Técnica:** el modelo de lenguaje extrae entidades (género musical, ciudad, tipo de artista) del texto libre y las mapea a los campos de la base de datos.

#### Mejora de Obras — AI Enhancement
El endpoint `POST /artworks/{id}/ai-enhance/` genera automáticamente:
- **Tags descriptivos:** palabras clave que describen la obra (técnica, estilo, temática)
- **Descripción enriquecida:** texto más elaborado basado en los metadatos de la obra

Esto ayuda al artista a mejorar la visibilidad de sus obras en búsquedas sin requerir habilidades de redacción.

#### Extracción de Datos de Afiches de Eventos
El endpoint de eventos culturales puede analizar la imagen de un afiche y extraer automáticamente: título del evento, fecha, lugar, tipo y descripción. El gestor cultural sube la imagen del afiche y recibe un borrador pre-llenado listo para revisar y publicar.

---

## 6. Base de Datos y Estructura de Datos

### 6.1 Elección de PostgreSQL

PostgreSQL es la base de datos relacional del sistema, elegida por:

- **Transacciones ACID:** garantías de atomicidad, consistencia, aislamiento y durabilidad — críticas para pagos y subastas
- **Tipos avanzados:** `JSONField` para datos semi-estructurados (tags de IA), `UUIDField` para IDs únicos globales, `ArrayField` para listas
- **Locking pesimista:** `SELECT FOR UPDATE` para concurrencia en pujas
- **Índices potentes:** índices compuestos, índices parciales para queries complejas

### 6.2 Modelo Relacional Principal

```
User (entidad central)
├── ArtistProfile (1:1) — datos del artista
│   └── Artwork (1:N) — obras del artista
│       ├── ArtworkImage (1:N) — galería
│       └── Category (N:1) — categoría
├── MusicianProfile (1:1) — datos del músico
│   ├── MusicGenre (N:M) — géneros musicales
│   └── MusicalWork (1:N) — obras musicales
├── Cart (1:1) — carrito activo del usuario
│   └── CartItem (1:N) → Artwork
└── Order (1:N) — historial de órdenes
    ├── OrderItem (1:N) → Artwork
    └── Transaction (1:1) → Wompi

Auction → Artwork (1:1 cuando está en subasta)
└── Bid (1:N) → User (pujador)

Event (creado por GESTOR_CULTURAL)
└── EventRegistration (1:N) → User

Follow (tabla intermedia User → ArtistProfile)
```

### 6.3 Estrategias de Optimización de Queries

**Evitar el problema N+1:** Al consultar una lista de obras con sus categorías, sin optimización Django haría una query por obra para obtener su categoría (N+1 queries para N obras). Se usa:

- `select_related()` para relaciones ForeignKey/OneToOne (hace JOIN en SQL)
- `prefetch_related()` para relaciones ManyToMany y reversas (hace query separada optimizada en batch)

**Índices en campos de filtro:** Los campos más usados en filtros y ordenamientos tienen índices explícitos: estado de obra, artista, categoría, precio, fecha de creación. Esto garantiza queries rápidas incluso con decenas de miles de registros.

**Paginación en todos los listados:** Ningún endpoint devuelve todos los registros sin límite. Se usa paginación por cursor (más eficiente) para listas grandes.

### 6.4 Migración y Versionado del Esquema

Django Migrations mantiene un historial versionado de todos los cambios en el esquema de la base de datos. Cada cambio (agregar campo, crear tabla, modificar índice) se representa como una migración reversible que puede aplicarse y revertirse de forma controlada.

En producción, las migraciones se ejecutan automáticamente al iniciar el servidor antes de aceptar tráfico.

---

## 7. Despliegue y Operaciones (DevOps)

### 7.1 Entornos

| Entorno | Infraestructura | Propósito |
|---------|----------------|-----------|
| **Desarrollo** | Docker Compose local | Cada desarrollador tiene todos los servicios en su máquina |
| **Producción** | Railway | Plataforma de hosting con PostgreSQL y Redis managed |

**Docker Compose en desarrollo:** Un solo comando (`docker-compose up`) levanta todos los servicios necesarios: Django, PostgreSQL, Redis, worker de Celery y N8N. Esto garantiza que todos los desarrolladores trabajan en el mismo ambiente sin "funciona en mi máquina".

**Railway en producción:** Plataforma de hosting que maneja el deployment automático desde el repositorio Git. Provee PostgreSQL y Redis como servicios managed (el equipo no gestiona infraestructura de base de datos manualmente).

### 7.2 Variables de Entorno

Toda configuración sensible se maneja mediante variables de entorno, nunca hardcodeada en el código:

```
# Base de datos
DATABASE_URL=postgresql://...

# Redis  
REDIS_URL=redis://...

# Seguridad
SECRET_KEY=...
ALLOWED_HOSTS=...

# Servicios externos
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
WOMPI_PUBLIC_KEY=...
WOMPI_PRIVATE_KEY=...
WOMPI_INTEGRITY_SECRET=...
RESEND_API_KEY=...
GEMINI_API_KEY=...
N8N_WEBHOOK_URL=...
```

La librería `python-decouple` lee estas variables con valores por defecto seguros para desarrollo. Si una variable no está definida en producción, el sistema falla explícitamente al arrancar (fail-fast), evitando errores sutiles en runtime.

### 7.3 Servidor de Producción (ASGI)

El servidor HTTP estándar de Django (WSGI) no soporta WebSockets. En producción se usa **Daphne** (servidor ASGI) que maneja tanto peticiones HTTP tradicionales como conexiones WebSocket en el mismo proceso. Esto simplifica el deployment — no se necesita un servidor separado para WebSockets.

### 7.4 Proceso de Inicio en Producción

Al arrancar el servidor en Railway, un script ejecuta en secuencia:

1. **Migraciones de base de datos** — aplica cualquier cambio nuevo en el esquema
2. **Creación del superusuario** — si no existe, crea la cuenta de administrador con credenciales de variables de entorno
3. **Inicio del servidor Daphne** — comienza a aceptar tráfico HTTP y WebSocket

El worker de Celery corre como un proceso separado en Railway, consumiendo la cola de tareas asíncronas.

---

## 8. Escalabilidad

### 8.1 Escalado Horizontal del Backend

Django es **stateless por diseño**: cada petición HTTP puede ser manejada por cualquier instancia del servidor sin necesidad de información de sesión local. El estado compartido (tokens, caché, colas) vive en Redis.

Esto permite agregar más instancias del servidor sin coordinación especial. Un load balancer distribuye el tráfico entre las instancias disponibles.

```
Usuario
   │
   ▼
Load Balancer
   ├── Django Instance 1
   ├── Django Instance 2
   └── Django Instance 3 ── Redis (estado compartido)
                              PostgreSQL (datos)
```

### 8.2 Escalado de WebSockets

Los WebSockets de subastas escalan con el mismo mecanismo. El Channel Layer de Redis actúa como bus de mensajes: cuando el servidor A recibe una puja, la publica en Redis; todos los servidores (A, B, C) que tienen usuarios suscritos a esa subasta reciben el mensaje y lo reenvían a sus clientes.

### 8.3 Escalado de la Base de Datos

PostgreSQL escala verticalmente (más CPU/RAM en el mismo nodo) para la mayoría de los casos. Para cargas muy altas se puede agregar **réplicas de lectura**: las queries de lectura (que son la mayoría del tráfico) van a réplicas; solo las escrituras van al nodo primario.

### 8.4 Escalado de Tareas Asíncronas

Los workers de Celery escalan horizontalmente de forma independiente al servidor web. En períodos de alta carga (muchas subastas cerrando simultáneamente, muchos emails en cola), se agregan más workers sin tocar el servidor principal.

### 8.5 CDN para Media

Cloudinary es un CDN global — no requiere escalar manualmente. Las imágenes se replican automáticamente a nodos en América, Europa y Asia. A mayor tráfico, las imágenes se sirven más rápido porque el nodo CDN más cercano al usuario las tiene en caché.

### 8.6 Escalado de Caché

El caché Redis absorbe la mayoría del tráfico de lectura para datos que cambian poco. Si Redis necesita escalar, se puede usar Redis Cluster que distribuye los datos entre múltiples nodos.

---

## 9. Buenas Prácticas Implementadas

### Seguridad
- Argon2 para hashing de contraseñas
- JWT con rotación de refresh tokens y blacklist
- RBAC con permisos declarativos por endpoint
- Rate limiting diferenciado por tipo de usuario y endpoint
- Verificación HMAC-SHA256 de webhooks de pago
- Variables de entorno para toda configuración sensible
- CORS configurado explícitamente para el dominio del frontend

### Calidad de Código
- TypeScript estricto en el frontend — errores detectados en compilación
- Serializers de DRF como capa de validación explícita
- Service Layer para encapsular lógica de negocio compleja
- Tests unitarios por módulo en el backend (factories + pytest)

### Resiliencia
- Fallback en cascada para el servicio de IA (microservicio → Gemini → reglas locales)
- Fallback de email (Resend → SMTP)
- Caché en memoria local si Redis no está disponible
- Transacciones atómicas con rollback en operaciones críticas
- Locking pesimista para prevenir race conditions en subastas

### Mantenibilidad
- Estructura modular por dominio
- Un directorio por módulo con sus modelos, vistas, serializers, URLs y tests
- Variables CSS semánticas para consistencia visual
- Componentes React reutilizables con props tipados (TypeScript)

### Observabilidad
- Logging estructurado en JSON en producción
- Middleware de auditoría que registra actividad de usuarios
- Endpoint `/health/` para monitoreo de disponibilidad
- Historial de notificaciones para auditoría

---

## 10. Flujos de Datos Principales

### 10.1 Flujo de Compra de Obra

```
1. Usuario navega catálogo (/artworks)
   → Frontend consulta GET /api/v1/artworks/?status=DISPONIBLE
   → TanStack Query cachea los resultados

2. Usuario agrega obra al carrito
   → Si autenticado: POST /api/v1/marketplace/cart/add/ → persiste en PostgreSQL
   → Si anónimo: agrega a cartStore → persiste en localStorage

3. Usuario va a checkout (/checkout)
   → Backend genera referencia y firma Wompi con HMAC-SHA256
   → Frontend renderiza widget de Wompi

4. Usuario completa pago en Wompi
   → Wompi notifica: POST /api/v1/payments/wompi/webhook/
   → Backend verifica firma → actualiza Orden (PAGADA), Artwork (VENDIDA)
   → Backend dispara webhook a N8N
   → N8N envía email de confirmación al comprador

5. Frontend muestra página de éxito
```

### 10.2 Flujo de Subasta en Tiempo Real

```
1. Artista crea subasta para su obra
   → PATCH artwork status → EN_SUBASTA
   → POST /api/v1/auctions/ → crea registro en PostgreSQL

2. Compradores entran a la sala (/auctions/{id})
   → Frontend abre WebSocket a ws://...{id}/
   → Server envía estado actual (precio base, pujas existentes)

3. Comprador puja
   → Frontend envía mensaje WebSocket con monto
   → Backend: SELECT FOR UPDATE (locking pesimista)
   → Valida: monto > precio actual, subasta activa
   → Persiste Bid en PostgreSQL, libera lock
   → Broadcast a todos los clientes conectados: nuevo precio
   → Todos los navegadores actualizan el precio simultáneamente

4. Celery Beat cierra la subasta (cada 60s revisa subastas vencidas)
   → AuctionService.close_auction() → marca ganador, cambia estado
   → Webhook a N8N → emails a ganador y artista
```

### 10.3 Flujo de Descubrimiento Musical con IA

```
1. Usuario escribe consulta en lenguaje natural
   → "Busco bandas de jazz de Pasto para una boda"

2. POST /api/v1/music-discovery/recommendations/
   → AIService extrae entidades del texto:
     - género: jazz
     - ciudad: Pasto
     - tipo: banda
     - contexto: evento privado

3. Backend construye filtros sobre MusicianProfile:
   → genre__name=jazz, city=Pasto, type=BANDA

4. Devuelve lista de músicos que coinciden
   → Frontend renderiza perfiles con fotos, géneros, contacto
```

---

## 11. Conexión entre Componentes (Diagrama de Servicios)

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (React SPA)                      │
│  TanStack Query │ Zustand │ React Hook Form │ WebSocket      │
└────────────────────────────────┬────────────────────────────┘
                                 │ HTTP + WebSocket
                                 ▼
┌─────────────────────────────────────────────────────────────┐
│               BACKEND (Django + Channels + Celery)           │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ REST API │  │ WebSocket│  │  Celery  │  │ Services │   │
│  │  (DRF)   │  │ Consumer │  │  Workers │  │  Layer   │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
└───────┼─────────────┼─────────────┼──────────────┼─────────┘
        │             │             │              │
   ┌────▼──┐    ┌─────▼─────┐  ┌───▼───┐    ┌────▼──────────┐
   │ Post- │    │   Redis   │  │ Redis │    │  Servicios    │
   │ greSQL│    │ (Channels │  │(Colas)│    │  Externos:    │
   │       │    │  Layer)   │  │       │    │  Cloudinary   │
   └───────┘    └───────────┘  └───────┘    │  Wompi        │
                                            │  N8N          │
                                            │  Resend/SMTP  │
                                            │  Gemini API   │
                                            └───────────────┘
```

Cada servicio externo tiene una **interfaz de integración** definida en el código (`services/cloudinary.py`, `services/payment_service.py`, `services/email_service.py`, `services/ai_service.py`). Si un proveedor externo cambia o necesita reemplazarse, solo se modifica la clase de servicio correspondiente — el resto del sistema no necesita cambios.

---

## 12. Decisiones Técnicas Clave (Architecture Decision Records)

### ADR 001 — Service Layer Separado de las Vistas
**Problema:** La lógica de negocio compleja (crear subasta, procesar checkout) mezclada en las vistas hace el código difícil de testear y mantener.  
**Decisión:** Capa de servicios explícita con clases que no dependen del framework HTTP.  
**Resultado:** Las vistas tienen < 20 líneas; los servicios son 100% testeables sin montar el servidor.

### ADR 002 — WebSockets con Django Channels vs. Server-Sent Events
**Problema:** Las subastas necesitan comunicación bidireccional en tiempo real.  
**Decisión:** Django Channels (WebSocket) sobre SSE porque permite autenticar al usuario en la conexión y escalar horizontalmente con Redis Channel Layer.  
**Resultado:** Un solo servidor ASGI (Daphne) maneja HTTP y WebSocket sin infraestructura adicional.

### ADR 003 — JWT Stateless vs. Sesiones Django
**Problema:** El sistema necesita escalar horizontalmente — las sesiones de servidor son stateful y no escalan.  
**Decisión:** JWT stateless con refresh token en blacklist. Las instancias del servidor no comparten estado de sesión.  
**Resultado:** Cualquier instancia puede validar cualquier token sin consultar estado compartido. El logout sigue siendo posible via blacklist en base de datos.

### ADR 004 — Cloudinary para Almacenamiento de Media
**Problema:** Railway tiene filesystem efímero — las imágenes se perderían al redeployar.  
**Decisión:** Cloudinary como backend de storage para todas las imágenes.  
**Resultado:** Las imágenes persisten indefinidamente, se sirven desde CDN global, y el sistema funciona igualmente en desarrollo (filesystem local) y producción (Cloudinary).

### ADR 005 — Arquitectura Híbrida de Emails (Django directo + N8N)
**Problema:** Si N8N falla, los emails de autenticación no llegarían, bloqueando el acceso al sistema.  
**Decisión:** Emails de autenticación (verificación, reset) van directo desde Django vía SMTP. Emails de negocio (subastas, eventos) van via N8N.  
**Resultado:** El sistema de autenticación funciona aunque N8N esté caído. N8N agrega valor para flujos de negocio sin ser un punto único de falla.

### ADR 006 — Fallback en Cascada para IA
**Problema:** Los servicios de IA externos son costosos y pueden no estar disponibles.  
**Decisión:** Tres niveles de fallback: microservicio FastAPI → Gemini API → reglas basadas en palabras clave.  
**Resultado:** Las funcionalidades de IA siempre responden aunque degraden en calidad.

---

## 13. Resumen de Tecnologías

| Categoría | Tecnología | Propósito |
|-----------|-----------|-----------|
| **Backend framework** | Django 5.1.7 + DRF | API REST, ORM, admin |
| **Tiempo real** | Django Channels (ASGI) | WebSockets para subastas |
| **Tareas asíncronas** | Celery + Celery Beat | Colas, tareas periódicas |
| **Broker de mensajes** | Redis | Colas Celery + Channel Layer |
| **Caché** | Redis (django-redis) | Caché de datos frecuentes |
| **Base de datos** | PostgreSQL | Datos relacionales |
| **Autenticación** | JWT (SimpleJWT) | Tokens stateless |
| **Hashing** | Argon2 | Contraseñas seguras |
| **Almacenamiento** | Cloudinary | CDN de imágenes |
| **Pagos** | Wompi | Pasarela de pago colombiana |
| **Email** | Resend / Brevo SMTP | Email transaccional |
| **Automatización** | N8N | Flujos de notificación |
| **IA** | Gemini API (Google) | Chat y generación de contenido |
| **Frontend framework** | React 19 + TypeScript | SPA de la plataforma |
| **Build tool** | Vite | Bundling y desarrollo |
| **Routing** | React Router v6 | Navegación SPA |
| **Estado servidor** | TanStack Query | Caché y sync de datos de API |
| **Estado cliente** | Zustand | Estado de sesión y UI |
| **Forms** | React Hook Form + Zod | Validación declarativa |
| **Estilos** | Tailwind CSS | Clases utilitarias + tokens |
| **HTTP client** | Axios | Peticiones HTTP con interceptores |
| **Hosting backend** | Railway | PaaS con PostgreSQL y Redis |
| **Automatización** | N8N en Render | Flujos de notificación independientes |

---

*Documento generado para la exposición de grado del proyecto Nariño Cultura — Ecosistema Digital Cultural del Departamento de Nariño, Colombia.*  
*Universidad Cooperativa de Colombia (UCC) × Corpocarnaval — 2025*
