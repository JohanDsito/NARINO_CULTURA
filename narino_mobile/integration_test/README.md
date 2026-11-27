# Pruebas de integración (móvil)

Archivos: `integration_test.dart` (MO-IN-01..16) y `performance_test.dart` (MO-PE-01..05).

## Regla de seguridad

Nunca corren contra producción. Al inicio de `main()` el guard `support/entorno_pruebas.dart`
exige `--dart-define=API_BASE_URL=...` y aborta si la URL contiene `railway.app` o `narinocultura`.
MO-IN-03 (registro, crea un usuario real) solo corre si la URL es local (localhost, 127.0.0.1,
10.0.2.2, 192.168.x.x o 10.x.x.x); si no, se omite (`skip`).

## 1. Levantar el backend local

```
cd narino_backend
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Crea antes un usuario de pruebas en esa base local (el que usarás en `TEST_EMAIL`/`TEST_PASSWORD`).

## 2. Correr en un celular real o emulador

El celular y el PC deben estar en la misma red (en el emulador Android se puede usar `http://10.0.2.2:8000`).

```
cd narino_mobile
flutter test integration_test/integration_test.dart \
  --dart-define=API_BASE_URL=http://<IP-del-PC>:8000 \
  --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
```

Rendimiento: igual con `integration_test/performance_test.dart`.

## 3. Guardar evidencia

```
mkdir -p evidencias
flutter test integration_test/integration_test.dart --reporter expanded \
  --dart-define=API_BASE_URL=http://<IP-del-PC>:8000 \
  --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=... > evidencias/integration_AAAA-MM-DD.txt
```

## Pendiente

Ejecutarlas en un emulador dentro de CI queda como trabajo futuro.
