# Nariño Cultura — App Móvil

Aplicación móvil Flutter para explorar, difundir y comercializar arte y cultura del departamento de Nariño (Colombia). Desarrollada como proyecto de grado para la asignatura de Ingeniería de Software en la Universidad Cooperativa de Colombia.

---

## Características principales

| Módulo | Descripción |
|---|---|
| Autenticación | Registro/login con JWT, verificación de correo, roles (Artista / Comprador / Gestor) |
| Catálogo de obras | Búsqueda, filtros por categoría, técnica y precio, ordenamiento, favoritos |
| Marketplace | Carrito de compras, checkout, historial de pedidos |
| Subastas | Pujas en tiempo real via WebSocket |
| Agenda cultural | Lista y detalle de eventos, recordatorios, mapa integrado (OpenStreetMap) |
| Perfil de artista | Bio, portafolio, seguidores, redes sociales |
| Inteligencia Artificial | Chatbot cultural y recomendaciones personalizadas |
| Notificaciones | Centro de notificaciones generadas por n8n |

---

## Stack tecnológico

- **Flutter / Dart** — SDK móvil multiplataforma
- **Riverpod** — gestión de estado (StateNotifier + FutureProvider)
- **go_router** — navegación declarativa con rutas anidadas
- **Dio** — cliente HTTP con interceptor JWT (refresh automático)
- **flutter_map + OpenStreetMap** — mapas sin clave de API
- **web_socket_channel** — WebSocket para subastas en tiempo real
- **cached_network_image** — imágenes con caché
- **flutter_secure_storage** — almacenamiento seguro de tokens

---

## Arquitectura

```
lib/
├── core/
│   ├── constants/      # ApiConstants, EnvConstants
│   ├── network/        # ApiClient (Dio + interceptores)
│   ├── providers/      # Providers globales (rol, claims JWT)
│   ├── theme/          # Colores, tipografía
│   └── utils/          # StorageUtils
├── features/
│   ├── auth/           # Login, registro, recuperación de contraseña
│   ├── artworks/       # Catálogo, detalle, publicación de obras
│   ├── auctions/       # Listado y detalle de subastas, puja en tiempo real
│   ├── events/         # Agenda cultural, detalle con mapa
│   ├── home/           # Pantalla principal con highlights y recomendaciones IA
│   ├── marketplace/    # Carrito, favoritos, pedidos, historial
│   ├── notifications/  # Centro de notificaciones
│   └── profile/        # Perfil propio, edición, portafolio, artistas seguidos
└── shared/
    └── widgets/        # ArtworkCard, EventCard y demás widgets reutilizables
```

Cada feature sigue la separación **data / domain / presentation**:
- `data/` — servicio HTTP + repositorio
- `domain/` — modelos, estado (State classes), enums
- `presentation/` — pantallas, providers Riverpod, widgets específicos del feature

---

## Configuración de entornos

Las URLs base se seleccionan automáticamente según el modo de compilación:

| Entorno | API REST | WebSocket |
|---|---|---|
| Desarrollo (emulador Android) | `http://10.0.2.2:8000/api/v1` | `ws://10.0.2.2:8000/ws/auctions/` |
| Producción (Railway) | `https://narinocultura-production.up.railway.app/api/v1` | `wss://narinocultura-production.up.railway.app/ws/auctions/` |

La selección es automática: las compilaciones `--release` usan producción, el resto usa desarrollo. No se requieren variables de entorno ni archivos `.env`.

> ❌ No se incluyen credenciales ni claves privadas en el repositorio.

---

## Requisitos

- Flutter SDK ≥ 3.19 (`flutter --version` para verificar)
- Android SDK con un emulador Pixel API 33+ o dispositivo físico
- Backend Django ejecutándose localmente **o** acceso al entorno de Railway

---

## Instalación y ejecución

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar en modo debug (apunta a 10.0.2.2:8000)
flutter run

# 3. Ejecutar apuntando al backend de Railway en modo debug
flutter run --dart-define=dart.vm.product=true
```

---

## Pruebas

```bash
# Análisis estático
flutter analyze

# Pruebas de widgets (MO-WT-01 a MO-WT-10)
flutter test

# Cobertura (requiere lcov instalado)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Pruebas de widget incluidas (MO-WT-01 a MO-WT-10)

| ID | Descripción |
|---|---|
| MO-WT-01 | LoginScreen renderiza los campos de correo y contraseña |
| MO-WT-02 | RegisterScreen muestra los tres chips de rol |
| MO-WT-03 | CatalogScreen muestra el título "Catálogo de Obras" |
| MO-WT-04 | HomeScreen muestra el nombre "Nariño Cultura" |
| MO-WT-05 | ArtworkCard muestra título y nombre del artista |
| MO-WT-06 | ArtworkCard sin imágenes muestra el ícono de paleta |
| MO-WT-07 | ArtworkCard formatea el precio con separadores de miles (COP) |
| MO-WT-08 | ArtworkCard muestra el badge "Vendida" cuando el estado es `vendida` |
| MO-WT-09 | MyProfileScreen muestra las opciones principales del menú |
| MO-WT-10 | MyProfileScreen muestra las opciones de favoritos y compras |

---

## Generar APK de producción

```bash
flutter build apk --release
```

El APK generado se encuentra en:
```
build/app/outputs/flutter-apk/app-release.apk
```

> La firma utiliza el keystore de debug de Android, aceptable para entrega académica.

---

## Integrantes

| Nombre | Rol |
|---|---|
| Johan David Delgado Delgado | Desarrollo backend y despliegue |
| Juan Manuel Matabanchoy Cabrera | Desarrollo móvil y pruebas |
| Valery Nickol Rosero Molina | Desarrollo móvil y diseño de interfaz |

**Universidad Cooperativa de Colombia**
Programa de Ingeniería de Software — 2026
