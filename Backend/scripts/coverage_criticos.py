"""Exige una cobertura mínima (líneas + ramas) en los módulos críticos del backend.

El umbral global del CI puede cumplirse con módulos fáciles mientras pagos o permisos quedan
sin probar; este script revisa cada grupo crítico por separado.

Uso (desde Backend/narinocultura_backend, después de `coverage run`):
    python -m coverage json --rcfile=../pyproject.toml -o coverage.json
    python ../scripts/coverage_criticos.py coverage.json
"""

import json
import sys
from pathlib import PurePath

MINIMO = 90.0

# Grupo -> prefijos de ruta (relativos a narinocultura_backend, con "/")
CRITICOS = {
    "pagos": ("apps/payments/", "services/payment_service.py"),
    "subastas": ("apps/auctions/", "services/auction_service.py"),
    "eventos": ("apps/events/", "services/event_service.py"),
    "usuarios": ("apps/users/",),
    "tienda": ("apps/marketplace/", "services/marketplace_service.py"),
    "ia": ("services/llm.py", "services/ai_service.py", "services/ai_rules.py"),
}


def main(ruta_json: str) -> int:
    with open(ruta_json, encoding="utf-8") as f:
        archivos = json.load(f)["files"]

    fallos = []
    for grupo, prefijos in CRITICOS.items():
        total = cubiertas = 0
        for nombre, datos in archivos.items():
            ruta = PurePath(nombre).as_posix()
            if ruta.startswith(prefijos):
                resumen = datos["summary"]
                total += resumen["num_statements"] + resumen["num_branches"]
                cubiertas += resumen["covered_lines"] + resumen["covered_branches"]
        porcentaje = 100.0 * cubiertas / total if total else 100.0
        estado = "ok" if porcentaje >= MINIMO else "BAJO"
        print(f"{grupo:<10} {porcentaje:6.2f} %  {estado}")
        if porcentaje < MINIMO:
            fallos.append(grupo)

    if fallos:
        print(f"\nCobertura por debajo de {MINIMO:.0f} % en: {', '.join(fallos)}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "coverage.json"))
