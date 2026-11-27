# Medición de rendimiento de la API

`medir_api.py` mide la latencia de los endpoints públicos de lectura (RNF07/RNF08: meta **p95 < 2 s**).
Solo usa la biblioteca estándar de Python 3.12, no necesita instalar nada y **solo hace solicitudes GET**.
Vive fuera de `Backend/` para no afectar la cobertura ni el CI del backend.

## Cómo correrlo

```bash
# Backend local (por ejemplo, runserver en el puerto 8010 con datos de demo)
python tools/rendimiento/medir_api.py --base-url http://127.0.0.1:8010 --concurrencia 10 --total 1000 \
    --calentamiento 10 --etiqueta local --salida resultados

# Producción (solo lectura y ligera; ver límites)
python tools/rendimiento/medir_api.py --base-url https://narinocultura-production.up.railway.app \
    --concurrencia 5 --total 300 --calentamiento 10 --etiqueta produccion --salida resultados
```

| Argumento | Qué hace |
|---|---|
| `--base-url` | URL base de la API (obligatorio). |
| `--concurrencia` | Solicitudes simultáneas (semáforo asyncio). Por defecto 10. |
| `--total` | Solicitudes de la medición, repartidas por turnos entre las rutas. Por defecto 1000. |
| `--rutas` | Rutas separadas por coma. `{obra}` se reemplaza por obras reales tomadas del listado `/api/v1/artworks/`. Por defecto: `/health/`, `/api/v1/artworks/`, `/api/v1/artworks/{obra}/`, `/api/v1/events/`, `/api/v1/artists/`. |
| `--detalles` | Cuántas obras distintas se usan para `{obra}` (por defecto 3). |
| `--calentamiento` | Solicitudes previas que no entran en las estadísticas. |
| `--etiqueta`, `--salida` | Prefijo y carpeta de los archivos de salida. |
| `--tasa-error-max`, `--graves-max` | Umbrales para detener la corrida (10 % de error o 3 respuestas 429/5xx). |

El GET de descubrimiento del catálogo cuenta dentro de `--total` (no se hacen solicitudes extra a escondidas).
Cada conexión es HTTP persistente (keep-alive), así que el tiempo de la primera conexión TLS solo se paga una vez por conexión.

## Límites para producción

Si `--base-url` contiene `railway.app`, el script **se niega a correr** con `--concurrencia` > 5,
`--total` > 300 o `--calentamiento` > 10. Además:

- Una sola corrida; sin login; nunca POST/PUT/DELETE (el cliente solo implementa GET).
- Se detiene solo (código de salida 2) si la tasa de error supera 10 % o aparecen 3 respuestas 429/5xx.
- Nota: el detalle de una obra suma una vista (`views_count`) como máximo una vez por obra y por IP en la ventana de
  `ARTWORK_VIEW_WINDOW_SECONDS`. Es el único efecto lateral posible de las lecturas.

## Salida

Por corrida se guardan en `--salida`:

- `<etiqueta>_<fecha>.json`: parámetros, resumen total, resumen por ruta y cada medición.
- `<etiqueta>_<fecha>.csv`: una fila por solicitud (`fase`, `ruta`, `url`, `estado`, `bytes`, `ms`, `ok`, `t_inicio_s`, `error`).

La consola muestra n, p50, p95, p99, máximo y errores por ruta, y el total con solicitudes por segundo.

## Cómo interpretar

- **Latencia**: milisegundos desde enviar la solicitud hasta leer el cuerpo completo de la respuesta.
- **Percentiles**: interpolación lineal entre rangos (equivale a `numpy.percentile` por defecto). p95 = el 95 % de las
  solicitudes tardó eso o menos. El requisito se cumple si el **p95 total y por ruta es < 2000 ms**.
- **Error**: estado HTTP >= 400, o fallo de red/timeout.
- **Solicitudes por segundo**: solicitudes de la medición / duración de la medición con la concurrencia indicada; depende de
  la concurrencia y del cliente, no es la capacidad máxima del servidor.
- **Contra producción** la latencia incluye la red entre el equipo que mide y Railway; contra local no hay red, pero el
  servidor de desarrollo (`runserver`) y SQLite no se parecen a producción. No comparar ambas cifras como si fueran lo mismo.
- Con pocas solicitudes por ruta (por ejemplo 40), p99 y máximo casi coinciden: usar con cautela.
