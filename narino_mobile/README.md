# Narino Cultura - App movil

Aplicacion movil desarrollada en Flutter para la plataforma Narino Cultura. Permite explorar obras artisticas, eventos culturales, subastas, marketplace, perfiles de artistas, musicos, recomendaciones y notificaciones del ecosistema cultural de Narino.

El proyecto hace parte de la solucion academica de Ingenieria de Software de la Universidad Cooperativa de Colombia.

---

## Funcionalidades principales

| Modulo | Descripcion |
|---|---|
| Autenticacion | Login, registro, recuperacion de contrasena, verificacion de correo, cierre de sesion y manejo de tokens JWT. |
| Catalogo de obras | Listado de obras, busqueda, filtros, detalle, favoritos, publicacion y edicion de obras. |
| Marketplace | Tienda, carrito, checkout, resultado de pago, historial de compras, historial de ventas y detalle de pedidos. |
| Subastas | Listado, detalle, historial, creacion de subastas y pujas en tiempo real por WebSocket. |
| Eventos culturales | Agenda de eventos, detalle, publicacion, mapa con OpenStreetMap y preferencias de notificacion. |
| Perfil | Perfil propio, edicion, portafolio, artistas seguidos, sesiones activas, cambio de correo, eliminacion de cuenta, estadisticas y politica de privacidad. |
| Inteligencia artificial | Chatbot cultural, recomendaciones de obras, recomendaciones de eventos y estadisticas para artistas. |
| Musicos | Listado de musicos, detalle por slug, publicacion de obras musicales, seguimiento y resenas. |
| Descubrimiento musical | Recomendaciones musicales consumidas desde el backend. |
| Notificaciones | Centro de notificaciones, contador de no leidas, marcar como leida y marcar todas como leidas. |

---

## Stack tecnologico

- Flutter y Dart.
- Riverpod para gestion de estado y providers.
- go_router para navegacion declarativa y proteccion de rutas.
- Dio para consumo HTTP.
- flutter_secure_storage para guardar tokens JWT de forma segura.
- web_socket_channel para subastas en tiempo real.
- cached_network_image para cache de imagenes remotas.
- flutter_map y latlong2 para mapas con OpenStreetMap.
- table_calendar para vistas de calendario.
- image_picker, photo_view, video_player, share_plus y url_launcher para flujos multimedia y acciones externas.
- google_fonts y tema propio para identidad visual.

---

## Arquitectura

La app usa una arquitectura modular por funcionalidades. La estructura general es:

```text
lib/
|-- main.dart                  # Inicializa Flutter, ApiClient y ProviderScope.
|-- app.dart                   # MaterialApp.router, rutas, redirecciones y shell principal.
|-- core/
|   |-- constants/             # URLs, endpoints y constantes generales.
|   |-- network/               # Cliente Dio e interceptor JWT.
|   |-- providers/             # Providers globales, rol de usuario y tema.
|   |-- theme/                 # Colores, tipografia y ThemeData.
|   `-- utils/                 # Utilidades compartidas, como almacenamiento seguro.
|-- features/
|   |-- ai/                    # Chatbot y recomendaciones.
|   |-- artworks/              # Obras, catalogo, detalle y publicacion.
|   |-- auctions/              # Subastas, pujas y WebSocket.
|   |-- auth/                  # Login, registro y seguridad de acceso.
|   |-- events/                # Eventos culturales y preferencias.
|   |-- home/                  # Pantalla principal.
|   |-- marketplace/           # Tienda, carrito, pagos, favoritos y pedidos.
|   |-- musicians/             # Perfil musical y obras musicales.
|   |-- music_discovery/       # Recomendaciones musicales.
|   |-- notifications/         # Notificaciones de usuario.
|   `-- profile/               # Perfil, portafolio y seguridad de cuenta.
`-- shared/
    |-- models/                # Modelos reutilizables.
    `-- widgets/               # Widgets compartidos como ArtworkCard, AppAvatar y NcButton.
```

La mayoria de features siguen esta separacion:

- `data/`: servicios HTTP, clientes especificos y repositorios.
- `domain/`: modelos, estados y estructuras del negocio.
- `presentation/`: pantallas, providers y widgets de interfaz.

---

## Flujo de arranque y navegacion

El punto de entrada esta en `lib/main.dart`:

1. Ejecuta `WidgetsFlutterBinding.ensureInitialized()`.
2. Inicializa `ApiClient.instance.init()` para activar Dio y el interceptor JWT.
3. Envuelve la app en `ProviderScope`.
4. Renderiza `NarinoCulturaApp`.

La navegacion vive en `lib/app.dart` y usa `GoRouter`.

- La ruta inicial es `/login`.
- Las rutas publicas son `/login`, `/register`, `/forgot-password` y `/verify-email-pending`.
- Si no hay token, el usuario vuelve a `/login`.
- Si ya hay token y entra a una ruta publica, se redirige a `/home`.
- Si el correo no esta verificado, solo se permiten algunas rutas de consulta como home, catalogo, marketplace, eventos, subastas, obras, artistas, musicos y perfil artistico.
- La navegacion principal usa `ShellRoute` con `BottomNavigationBar`: Inicio, Catalogo, Tienda, Subastas, Eventos y Perfil.

---

## Capa de red y autenticacion

La comunicacion con el backend se centraliza en `ApiClient`.

Componentes importantes:

- `ApiConstants`: define endpoints REST, WebSocket y timeouts.
- `EnvConstants`: define las URLs base actuales del backend.
- `ApiClient`: crea una unica instancia de Dio con `baseUrl`, timeouts y headers JSON.
- `AuthInterceptor`: agrega `Authorization: Bearer <token>` a cada peticion protegida.
- `StorageUtils`: guarda, lee y elimina access token y refresh token con `flutter_secure_storage`.

El interceptor tambien maneja refresh automatico:

1. Si una peticion responde `401`, intenta renovar el access token con el refresh token.
2. Si el refresh funciona, repite la peticion original.
3. Si falla, limpia los tokens guardados.

Para llamadas sin autenticacion se usa `Options(extra: {'__skipAuth': true})`. Para evitar refresh automatico se usa `__skipAuthRefresh`.

---

## Configuracion de entorno

Las URLs estan en `lib/core/constants/env_constants.dart`.

```dart
static const String apiBaseUrl =
    'https://narinocultura-production.up.railway.app';

static const String auctionWsBaseUrl =
    'wss://narinocultura-production.up.railway.app/ws/auctions/';
```

Actualmente la app apunta al backend desplegado en Railway. Para trabajar con un backend local se debe cambiar temporalmente `apiBaseUrl` y `auctionWsBaseUrl`.

Ejemplo para emulador Android:

```dart
static const String apiBaseUrl = 'http://10.0.2.2:8000';
static const String auctionWsBaseUrl = 'ws://10.0.2.2:8000/ws/auctions/';
```

No se deben guardar credenciales reales en el repositorio.

---

## Rutas principales

| Ruta | Pantalla |
|---|---|
| `/login` | Inicio de sesion |
| `/register` | Registro |
| `/home` | Inicio |
| `/catalog` | Catalogo de obras |
| `/artworks/:id` | Detalle de obra |
| `/artworks/publish` | Publicar obra |
| `/marketplace` | Tienda |
| `/marketplace/cart` | Carrito |
| `/marketplace/checkout` | Checkout |
| `/auctions` | Subastas |
| `/auctions/:id` | Detalle de subasta |
| `/events` | Eventos |
| `/events/:id` | Detalle de evento |
| `/chatbot` | Chatbot cultural |
| `/musicians` | Musicos |
| `/musicians/:slug` | Detalle de musico |
| `/music-discovery` | Descubrimiento musical |
| `/notifications` | Notificaciones |
| `/profile` | Mi perfil |

---

## Requisitos

- Flutter SDK compatible con Dart `>=3.0.0 <4.0.0`.
- Android Studio, Android SDK o un dispositivo/emulador configurado.
- Acceso al backend de Railway o backend local compatible.

Verificar instalacion:

```bash
flutter doctor
flutter --version
```

---

## Instalacion y ejecucion

Desde la carpeta `narino_mobile`:

```bash
flutter pub get
flutter run
```

Para ejecutar en un dispositivo especifico:

```bash
flutter devices
flutter run -d <device_id>
```

---

## Pruebas

Analisis estatico:

```bash
flutter analyze
```

Pruebas de widget:

```bash
flutter test
```

Pruebas de integracion con credenciales por `dart-define`:

```bash
flutter test integration_test/integration_test.dart \
  --dart-define=TEST_EMAIL=tu_correo \
  --dart-define=TEST_PASSWORD=tu_contrasena
```

Pruebas de rendimiento:

```bash
flutter test integration_test/performance_test.dart \
  --profile \
  --dart-define=TEST_EMAIL=tu_correo \
  --dart-define=TEST_PASSWORD=tu_contrasena
```

Cobertura:

```bash
flutter test --coverage
```

---

## Pruebas incluidas

El archivo `test/widget_test.dart` contiene pruebas MO-WT-01 a MO-WT-10 para validar pantallas y widgets principales:

- Login y registro.
- Catalogo de obras.
- Home.
- `ArtworkCard`.
- Perfil propio.
- Favoritos y compras.

El archivo `integration_test/integration_test.dart` contiene pruebas MO-IN-01 a MO-IN-16 para flujos completos:

- Login correcto e incorrecto.
- Registro.
- Catalogo, busqueda y filtros.
- Detalle de obra.
- Favoritos y carrito.
- Eventos y detalle.
- Subastas.
- Perfil.
- Notificaciones.
- Cierre de sesion.

El archivo `integration_test/performance_test.dart` contiene pruebas MO-PE-01 a MO-PE-05:

- Tiempo de arranque.
- Fluidez de scroll.
- Carga de imagenes.
- Transiciones entre pantallas.
- Uso de memoria durante una sesion completa.

---

## Generar APK

```bash
flutter build apk --release
```

El archivo generado queda en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Integrantes

| Nombre | Rol |
|---|---|
| Johan David Delgado Delgado | Desarrollo backend y despliegue |
| Juan Manuel Matabanchoy Cabrera | Desarrollo frontend y pruebas |
| Valery Nickol Rosero Molina | Desarrollo movil, diseno de interfaz y pruebas |

Universidad Cooperativa de Colombia  
Programa de Ingenieria de Software - 2026
