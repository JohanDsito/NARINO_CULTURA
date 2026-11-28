# Pruebas de integración (móvil)

Archivos: `integration_test.dart` (MO-IN-01..16) y `performance_test.dart` (MO-PE-01..05).

## Regla de seguridad

Nunca corren contra producción. Al inicio de `main()` el guard `support/entorno_pruebas.dart`
exige `--dart-define=API_BASE_URL=...` y aborta si esa URL (o el WebSocket de subastas) contiene
`railway.app` o `narinocultura`. MO-IN-03 (registro, crea un usuario real) solo corre si el host es
local: `localhost`, loopback (127.x, ::1) o IP privada (10.x —incluye 10.0.2.2 del emulador—,
172.16–31.x, 192.168.x); si no, se omite (`skip`).

## 1. Levantar el backend local

Con la base local (SQLite por defecto; revisa que tu `.env` no apunte `DB_HOST` a una base remota).
`manage.py` usa por defecto los settings de **producción** (redirige a HTTPS y rechaza el host),
así que hay que pasar los de desarrollo y permitir la IP del PC:

```
cd Backend/narinocultura_backend
export DJANGO_SETTINGS_MODULE=config.settings.development
export ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2,<IP-del-PC>
python manage.py migrate
python manage.py createsuperuser   # este correo/clave van en TEST_EMAIL / TEST_PASSWORD
python manage.py runserver 0.0.0.0:8000
```

(PowerShell: `$env:DJANGO_SETTINGS_MODULE="config.settings.development"` y lo mismo con `ALLOWED_HOSTS`.)

## 2. Correr en un celular real o emulador

El celular y el PC deben estar en la misma red (en el emulador Android usa `http://10.0.2.2:8000`).
Comprueba antes que el celular abre `http://<IP-del-PC>:8000/health/` en el navegador.

```
cd narino_mobile
flutter devices
flutter test integration_test/integration_test.dart -d <id-del-dispositivo> \
  --dart-define=API_BASE_URL=http://<IP-del-PC>:8000 \
  --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
```

Rendimiento: lo mismo con `integration_test/performance_test.dart` y `--profile`.

## 3. Guardar evidencia

```
mkdir -p evidencias
flutter test integration_test/integration_test.dart -d <id-del-dispositivo> --reporter expanded \
  --dart-define=API_BASE_URL=http://<IP-del-PC>:8000 \
  --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=... 2>&1 | tee evidencias/integration_AAAA-MM-DD.txt
```

Revisa el archivo antes de compartirlo: no debe tener credenciales.

## Pendiente

Ejecutarlas en un emulador dentro de CI queda como trabajo futuro.
