#!/usr/bin/env python3
"""Mide la latencia de la API de Nariño Cultura (solo solicitudes GET).

Solo usa la biblioteca estándar (Python 3.12). Lanza solicitudes concurrentes (asyncio + semáforo),
registra la latencia de cada una y calcula p50, p95, p99, tasa de error y solicitudes por segundo.

Ejemplos:
    python medir_api.py --base-url http://127.0.0.1:8010 --concurrencia 10 --total 1000
    python medir_api.py --base-url https://narinocultura-production.up.railway.app \
        --concurrencia 5 --total 300 --calentamiento 10 --etiqueta produccion

Límites duros contra producción (URL con "railway.app"): concurrencia <= 5, total <= 300 y
calentamiento <= 10. El script se niega a correr si se superan.
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import http.client
import json
import platform
import sys
import time
from datetime import datetime
from pathlib import Path
from urllib.parse import urlsplit

RUTAS_POR_DEFECTO = "/health/,/api/v1/artworks/,/api/v1/artworks/{obra}/,/api/v1/events/,/api/v1/artists/"
RUTA_CATALOGO = "/api/v1/artworks/"
LIMITE_PROD = {"concurrencia": 5, "total": 300, "calentamiento": 10}
UMBRAL_P95_MS = 2000.0  # RNF07/RNF08: p95 < 2 s


def percentil(valores: list[float], p: float) -> float:
    """Percentil p (0-100) por interpolación lineal entre rangos (igual que numpy, método 7)."""
    if not valores:
        return float("nan")
    orden = sorted(valores)
    pos = (len(orden) - 1) * p / 100.0
    bajo = int(pos)
    alto = min(bajo + 1, len(orden) - 1)
    return orden[bajo] + (orden[alto] - orden[bajo]) * (pos - bajo)


def resumir(muestras: list[dict], duracion_s: float | None = None) -> dict:
    """Estadísticas de una lista de muestras (cada una con `ms` y `ok`)."""
    n = len(muestras)
    ms = [m["ms"] for m in muestras]
    errores = sum(1 for m in muestras if not m["ok"])
    res = {
        "n": n,
        "errores": errores,
        "tasa_error_pct": round(100.0 * errores / n, 2) if n else 0.0,
        "min_ms": round(min(ms), 2) if n else None,
        "media_ms": round(sum(ms) / n, 2) if n else None,
        "p50_ms": round(percentil(ms, 50), 2) if n else None,
        "p95_ms": round(percentil(ms, 95), 2) if n else None,
        "p99_ms": round(percentil(ms, 99), 2) if n else None,
        "max_ms": round(max(ms), 2) if n else None,
    }
    if duracion_s:
        res["solicitudes_por_segundo"] = round(n / duracion_s, 2)
    return res


def validar_limites(args: argparse.Namespace) -> None:
    """Se niega a correr contra producción (railway.app) por encima de los límites."""
    if "railway.app" not in args.base_url.lower():
        return
    excesos = [
        f"--{k} {getattr(args, k)} (máximo {v})"
        for k, v in LIMITE_PROD.items()
        if getattr(args, k) > v
    ]
    if excesos:
        sys.exit(
            "ERROR: contra producción (railway.app) los límites son concurrencia<=5, total<=300 y "
            "calentamiento<=10. Excedidos: " + ", ".join(excesos)
        )


class Cliente:
    """Pool de conexiones HTTP persistentes (keep-alive); su tamaño es el tope de concurrencia. Solo GET."""

    def __init__(self, base_url: str, concurrencia: int, timeout: float) -> None:
        partes = urlsplit(base_url)
        self.https = partes.scheme == "https"
        self.host = partes.netloc
        self.prefijo = partes.path.rstrip("/")
        self.timeout = timeout
        self.semaforo = asyncio.Semaphore(concurrencia)
        self.libres = [self._nueva() for _ in range(concurrencia)]

    def _nueva(self) -> http.client.HTTPConnection:
        clase = (
            http.client.HTTPSConnection if self.https else http.client.HTTPConnection
        )
        return clase(self.host, timeout=self.timeout)

    def _get(
        self, conexion: http.client.HTTPConnection, ruta: str
    ) -> tuple[int, bytes]:
        conexion.request(
            "GET",
            self.prefijo + ruta,
            headers={"Accept": "application/json", "User-Agent": "medir_api/1.0"},
        )
        resp = conexion.getresponse()
        return resp.status, resp.read()

    async def get(self, ruta: str) -> tuple[int, bytes, float]:
        """GET; devuelve (estado, cuerpo, ms) con la latencia medida hasta leer el cuerpo completo."""
        async with self.semaforo:
            conexion = self.libres.pop()
            inicio = time.perf_counter()
            try:
                estado, cuerpo = await asyncio.to_thread(self._get, conexion, ruta)
            except BaseException:
                conexion.close()
                conexion = self._nueva()
                raise
            finally:
                self.libres.append(conexion)
        return estado, cuerpo, (time.perf_counter() - inicio) * 1000.0

    def cerrar(self) -> None:
        for c in self.libres:
            c.close()


class Vigilante:
    """Detiene la corrida si la tasa de error o los 429/5xx repetidos superan el umbral."""

    def __init__(self, tasa_max: float, graves_max: int, minimo: int = 20) -> None:
        self.tasa_max, self.graves_max, self.minimo = tasa_max, graves_max, minimo
        self.n = self.err = self.graves = 0
        self.motivo = ""

    def registrar(self, m: dict) -> None:
        self.n += 1
        self.err += 0 if m["ok"] else 1
        self.graves += 1 if (m["estado"] == 429 or m["estado"] >= 500) else 0
        if self.motivo:
            return
        if self.graves >= self.graves_max:
            self.motivo = f"{self.graves} respuestas 429/5xx (límite {self.graves_max})"
        elif self.n >= self.minimo and self.err / self.n > self.tasa_max:
            self.motivo = f"tasa de error {100 * self.err / self.n:.1f} % > {100 * self.tasa_max:.0f} %"


async def medir(
    cliente: Cliente, url: str, plantilla: str, fase: str, t0: float
) -> tuple[dict, bytes]:
    inicio = time.perf_counter()
    m = {
        "fase": fase,
        "ruta": plantilla,
        "url": url,
        "estado": 0,
        "bytes": 0,
        "ms": 0.0,
        "ok": False,
        "t_inicio_s": round(inicio - t0, 4),
        "error": "",
    }
    cuerpo = b""
    try:
        estado, cuerpo, ms = await cliente.get(url)
        m.update(estado=estado, bytes=len(cuerpo), ms=ms, ok=200 <= estado < 400)
    except Exception as exc:  # red caída o timeout: cuenta como error
        m.update(ms=(time.perf_counter() - inicio) * 1000.0, error=type(exc).__name__)
    return m, cuerpo


def extraer_ids(cuerpo: bytes, cuantos: int) -> list[str]:
    """Identificadores de obras del listado (el detalle de /artworks/ se pide por id; si hubiera slug, se usa)."""
    try:
        datos = json.loads(cuerpo)
    except ValueError:
        return []
    items = datos.get("results", datos) if isinstance(datos, dict) else datos
    ids = [
        str(o.get("slug") or o.get("id"))
        for o in items
        if isinstance(o, dict) and (o.get("slug") or o.get("id"))
    ]
    return ids[:cuantos]


def expandir(plantillas: list[str], slugs: list[str]) -> list[tuple[str, str]]:
    """Pares (url, plantilla): cada ruta con {obra} se convierte en una ruta por slug descubierto."""
    rutas: list[tuple[str, str]] = []
    for p in plantillas:
        if "{obra}" in p:
            rutas += [(p.replace("{obra}", s), p) for s in slugs]
        else:
            rutas.append((p, p))
    return rutas


async def ejecutar(args: argparse.Namespace) -> tuple[dict, int]:
    cliente = Cliente(args.base_url, args.concurrencia, args.timeout)
    vigilante = Vigilante(args.tasa_error_max, args.graves_max)
    t0 = time.perf_counter()
    plantillas = [r.strip() for r in args.rutas.split(",") if r.strip()]
    medidas: list[dict] = []
    todas: list[dict] = []
    slugs: list[str] = []

    # Descubrimiento: los slugs del detalle salen del propio listado del catálogo. Ese GET cuenta en el total.
    if any("{obra}" in p for p in plantillas):
        m, cuerpo = await medir(cliente, RUTA_CATALOGO, RUTA_CATALOGO, "medicion", t0)
        medidas.append(m)
        todas.append(m)
        vigilante.registrar(m)
        slugs = extraer_ids(cuerpo, args.detalles)
        if not slugs:
            cliente.cerrar()
            sys.exit(
                "ERROR: no se pudieron obtener obras del catálogo para medir el detalle."
            )
    rutas = expandir(plantillas, slugs)

    async def lote(
        pares: list[tuple[str, str]], fase: str, destino: list[dict]
    ) -> None:
        async def una(url: str, plantilla: str) -> None:
            if vigilante.motivo:
                return
            m, _ = await medir(cliente, url, plantilla, fase, t0)
            destino.append(m)
            todas.append(m)
            vigilante.registrar(m)

        await asyncio.gather(*(una(u, p) for u, p in pares))

    # Calentamiento (no entra en las estadísticas).
    if args.calentamiento:
        await lote(
            [rutas[i % len(rutas)] for i in range(args.calentamiento)],
            "calentamiento",
            [],
        )

    pendientes = args.total - len(medidas)
    plan = [rutas[i % len(rutas)] for i in range(max(pendientes, 0))]
    inicio = time.perf_counter()
    await lote(plan, "medicion", medidas)
    duracion = time.perf_counter() - inicio
    cliente.cerrar()

    por_ruta = {}
    for ruta in dict.fromkeys(
        m["ruta"] for m in medidas
    ):  # agrupa por plantilla: el detalle de varias obras es una fila
        por_ruta[ruta] = resumir([m for m in medidas if m["ruta"] == ruta])
    resultado = {
        "etiqueta": args.etiqueta,
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "parametros": {
            "base_url": args.base_url,
            "concurrencia": args.concurrencia,
            "total": args.total,
            "calentamiento": args.calentamiento,
            "rutas": args.rutas,
            "detalles": args.detalles,
            "timeout_s": args.timeout,
            "slugs_detalle": slugs,
            "solo_metodo": "GET",
        },
        "cliente": {
            "python": platform.python_version(),
            "sistema": platform.platform(),
        },
        "duracion_medicion_s": round(duracion, 3),
        "abortada": vigilante.motivo or None,
        "total": resumir(medidas, duracion),
        "por_ruta": por_ruta,
        "umbral_p95_ms": UMBRAL_P95_MS,
        "cumple_p95": (resumir(medidas)["p95_ms"] or 0) < UMBRAL_P95_MS
        if medidas
        else None,
        "mediciones": todas,
    }
    return resultado, (2 if vigilante.motivo else 0)


def guardar(resultado: dict, carpeta: Path) -> tuple[Path, Path]:
    carpeta.mkdir(parents=True, exist_ok=True)
    base = (
        carpeta / f"{resultado['etiqueta']}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    )
    ruta_json, ruta_csv = base.with_suffix(".json"), base.with_suffix(".csv")
    ruta_json.write_text(
        json.dumps(resultado, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    campos = [
        "fase",
        "ruta",
        "url",
        "estado",
        "bytes",
        "ms",
        "ok",
        "t_inicio_s",
        "error",
    ]
    with ruta_csv.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=campos)
        w.writeheader()
        for m in resultado["mediciones"]:
            w.writerow({**m, "ms": round(m["ms"], 3)})
    return ruta_json, ruta_csv


def imprimir(resultado: dict) -> None:
    print(f"\n{'ruta':<34}{'n':>6}{'p50':>9}{'p95':>9}{'p99':>9}{'max':>9}{'err':>5}")
    filas = list(resultado["por_ruta"].items()) + [("TOTAL", resultado["total"])]
    for ruta, r in filas:
        print(
            f"{ruta:<34}{r['n']:>6}{r['p50_ms']:>9}{r['p95_ms']:>9}{r['p99_ms']:>9}{r['max_ms']:>9}{r['errores']:>5}"
        )
    t = resultado["total"]
    print(
        f"\nsolicitudes/s: {t.get('solicitudes_por_segundo')}  tasa de error: {t['tasa_error_pct']} %  "
        f"p95 < {UMBRAL_P95_MS:.0f} ms: {'SI' if resultado['cumple_p95'] else 'NO'}"
    )
    if resultado["abortada"]:
        print(f"CORRIDA DETENIDA: {resultado['abortada']}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Mide la latencia de la API (solo GET).")
    ap.add_argument("--base-url", required=True, help="p. ej. http://127.0.0.1:8010")
    ap.add_argument("--concurrencia", type=int, default=10)
    ap.add_argument(
        "--total",
        type=int,
        default=1000,
        help="solicitudes de la medición (incluye el GET de descubrimiento)",
    )
    ap.add_argument(
        "--rutas",
        default=RUTAS_POR_DEFECTO,
        help="lista separada por comas; {obra} se reemplaza por slugs del catálogo",
    )
    ap.add_argument(
        "--detalles",
        type=int,
        default=3,
        help="cuántas obras distintas usar para {obra}",
    )
    ap.add_argument(
        "--calentamiento",
        type=int,
        default=0,
        help="solicitudes previas que no entran en las estadísticas",
    )
    ap.add_argument("--timeout", type=float, default=30.0)
    ap.add_argument("--etiqueta", default="medicion")
    ap.add_argument(
        "--salida", default="resultados", help="carpeta para el JSON y el CSV"
    )
    ap.add_argument(
        "--tasa-error-max",
        type=float,
        default=0.10,
        help="detiene la corrida si se supera (0.10 = 10 %%)",
    )
    ap.add_argument(
        "--graves-max",
        type=int,
        default=3,
        help="detiene la corrida con tantos 429/5xx",
    )
    args = ap.parse_args()
    if args.concurrencia < 1 or args.total < 1 or args.calentamiento < 0:
        sys.exit("ERROR: concurrencia y total deben ser >= 1.")
    validar_limites(args)
    resultado, codigo = asyncio.run(ejecutar(args))
    imprimir(resultado)
    ruta_json, ruta_csv = guardar(resultado, Path(args.salida))
    print(f"\nGuardado: {ruta_json}\n          {ruta_csv}")
    return codigo


if __name__ == "__main__":
    sys.exit(main())
