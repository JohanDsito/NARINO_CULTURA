# Pruebas end-to-end (Playwright)

Recorren la web real (build de producción servido con `vite preview`) contra el backend real, pero
aislado de todo servicio externo. **Nunca tocan producción**: el `global-setup` se detiene si
`E2E_API_URL` o `E2E_BASE_URL` mencionan `railway` o `narinocultura.uk`, y cada prueba aborta
cualquier petición a `*.railway.app` y `*.wompi.co`.

## Qué cubren

| Archivo | Flujo |
|---|---|
| `auth.spec.ts` | Registro (login bloqueado hasta verificar el correo), login de usuario verificado, contraseña incorrecta y ruta privada |
| `purchase.spec.ts` | Catálogo, detalle, carrito, checkout, `payments/initiate`, webhook de Wompi firmado en Node y orden "Pagado" en "Mis pedidos" |
| `auction.spec.ts` | Dos sesiones en la misma subasta: una puja y la otra la ve en vivo por WebSocket |
| `events-admin.spec.ts` | El artista crea un evento, el admin lo aprueba y aparece en eventos; el admin ve los usuarios |

Wompi se simula así: el back usa llaves falsas (`config/settings/e2e.py`), Playwright intercepta
`https://checkout.wompi.co/**` y la prueba firma el webhook con el secreto falso `e2e_events_secret`
(SHA-256 de `transaction.id + status + amount_in_cents + timestamp + secreto`) y lo envía al back.

## Correrlo en local

Necesitas Python 3.12 con las dependencias del backend (`pip install -r Backend/requirements-dev.txt`)
y Node 22. Todos los comandos parten de la raíz del repositorio.

```bash
# 1. Backend con los ajustes e2e (SQLite en archivo, sin Redis ni servicios externos)
cd Backend/narinocultura_backend
export DJANGO_SETTINGS_MODULE=config.settings.e2e   # PowerShell: $env:DJANGO_SETTINGS_MODULE="config.settings.e2e"
python manage.py migrate
python manage.py seed_demo --confirmar      # admin@, artista@ y comprador@demo.test (clave Demo1234!)
python -m daphne -b 127.0.0.1 -p 8000 config.asgi:application   # se usa daphne, no runserver (WebSockets)

# 2. Front (otra terminal). El build SIEMPRE con la URL local del back: sin ella apuntaría a producción
cd Front/Narino_Front
npm ci
VITE_API_BASE_URL=http://127.0.0.1:8000 npm run build   # PowerShell: $env:VITE_API_BASE_URL="http://127.0.0.1:8000"
npx vite preview --host 127.0.0.1 --port 4173 --strictPort

# 3. Pruebas (otra terminal)
cd Front/Narino_Front
npx playwright install chromium          # solo la primera vez
npm run e2e                              # reporte: npx playwright show-report
```

Notas:

- Base de datos: sin `DATABASE_URL` se usa `Backend/narinocultura_backend/e2e.sqlite3` (ignorado por git);
  en el CI se usa Postgres. Para empezar de cero, borra ese archivo y repite `migrate` y `seed_demo`.
- Las pruebas crean sus propios datos (usuarios, obras y eventos con nombres únicos), así que se pueden
  repetir sin volver a sembrar. La subasta sembrada acepta pujas cada vez más altas.
- En Windows, corre Playwright y Vitest desde una ruta con la letra de unidad en MAYÚSCULA (`C:/...`).
- Variables opcionales: `E2E_BASE_URL` (por defecto `http://127.0.0.1:4173`), `E2E_API_URL`
  (`http://127.0.0.1:8000`), `E2E_WOMPI_EVENTS_SECRET` (`e2e_events_secret`).
- `npm run e2e:typecheck` revisa los tipos de estas pruebas.
