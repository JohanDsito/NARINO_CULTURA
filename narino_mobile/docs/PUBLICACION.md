# Publicar la app en Google Play

| Dato | Valor |
|---|---|
| Identificador (`applicationId`) | **`uk.narinocultura.app`**: no se puede cambiar después de publicar |
| Nombre | Nariño Cultura |
| Versión | `version:` de `pubspec.yaml` (hoy `1.3.0+3`: nombre `1.3.0`, código `3`) |
| Android mínimo / objetivo | 7.0 (SDK 24) / SDK 36 |

## 1. Llave de firma

La app se firma con una **llave de subida** propia: `upload-keystore.jks`, con el alias `upload`.

- **Dónde está:** fuera del repositorio, en la carpeta personal del equipo de desarrollo (`C:\Users\nicky\.narino-cultura\`). Ahí hay también un `LEEME.txt` y un respaldo de las contraseñas.
- **Cómo la lee Gradle:** `android/app/build.gradle.kts` la busca en **`android/key.properties`**, que tiene `storeFile`, `storePassword`, `keyAlias` y `keyPassword`.
  - Ese archivo y los `.jks` están en `android/.gitignore`: **nunca se suben a GitHub**.
- **Sin `key.properties`**, como pasa en el CI, la versión release se firma con la llave de depuración. Sirve para probar en un celular, pero Google Play la rechaza.
- **Hay que guardar una copia de la carpeta en un lugar seguro.** Sin la llave no se pueden publicar actualizaciones.
  - Con la *Firma de apps de Google Play* activada (paso 3), Google puede reemplazar una llave de subida perdida a través de soporte.

Para firmar desde otro equipo: copiar el `.jks` y crear `android/key.properties` con la ruta nueva.

## 2. Compilar

Desde `narino_mobile/`:

```bash
flutter analyze && flutter test
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab  → para Google Play
flutter build apk --release         # build/app/outputs/flutter-apk/app-release.apk     → para instalar a mano
```

Por defecto la app usa el backend de producción. Para compilar contra otro servidor:
`--dart-define=API_BASE_URL=https://otro-servidor`. El WebSocket de subastas se deriva solo; si hace falta otro, se pasa `WS_BASE_URL`.

**Verificar la firma** (debe decir `CN=Narino Cultura`):

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk   # build-tools del SDK de Android
```

**Antes de cada envío**, subir el `versionCode`: el número después del `+` en `pubspec.yaml`. Google Play no acepta dos veces el mismo.

## 3. Google Play Console (primera vez)

1. Crear la app: nombre "Nariño Cultura", idioma español, tipo app, gratuita.
2. Activar la **Firma de apps de Google Play** y subir el primer `.aab`.
3. Completar la ficha:
   - Ícono 512×512: `assets/branding/icono_play_512.png`.
   - Gráfico de funciones de 1024×500: **pendiente**.
   - Al menos 2 capturas de celular: se pueden usar las de `docs/evidencias/`.
   - Descripción corta y descripción completa.
4. Completar los formularios:
   - **Política de privacidad: Google exige una URL pública.** El texto ya está en la app (Ajustes → Política de privacidad, v1.1), pero falta publicarlo en una página web.
   - Clasificación de contenido y público objetivo.
   - **Seguridad de los datos.** Datos que se recogen: nombre, correo, teléfono (opcional) y fotos de perfil y de obras.
     Servicios externos que los procesan:
     - Wompi (pagos)
     - Resend (correos)
     - Cloudinary (imágenes)
     - Gemini y Groq (chat e IA)

     Antes de enviar el formulario, confirmarlo contra el backend.
   - Acceso a la app: un usuario de prueba para la revisión de Google.
5. Publicar primero en **Prueba interna**, probar en celulares reales y después pasar a producción.

## 4. Íconos y pantalla de inicio

Las fuentes están en `assets/branding/`: la montaña blanca sobre el degradado naranja → magenta, la misma marca que la web.

Para regenerarlas:

```bash
python tool/generar_iconos.py assets/branding            # requiere Pillow
dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

La configuración de los dos generadores está al final de `pubspec.yaml`.
- **Ícono adaptable** (Android 8+): fondo con degradado, frente con la montaña y versión monocroma para los íconos temáticos de Android 13.
- **Pantalla de inicio:** fondo Carnaval claro u oscuro según el teléfono, con la marca en el centro.
