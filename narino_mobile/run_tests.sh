#!/usr/bin/env bash
# Orquestador de pruebas unitarias/widget de Nariño Cultura.
#
# `flutter test` ya descubre y corre TODOS los archivos *_test.dart bajo
# test/ automáticamente (no hace falta listarlos a mano); este script solo
# le da una salida más clara, agrupada por feature, y un resumen final.
#
# Uso:
#   ./run_tests.sh              # corre toda la suite
#   ./run_tests.sh artworks     # corre solo test/features/artworks/
#   ./run_tests.sh --coverage   # corre toda la suite y genera coverage/lcov.info

set -uo pipefail
cd "$(dirname "$0")"

FEATURE="${1:-}"
COVERAGE_ARGS=()

if [ "$FEATURE" = "--coverage" ]; then
  COVERAGE_ARGS=(--coverage)
  FEATURE=""
fi

TARGET="test"
if [ -n "$FEATURE" ] && [ -d "test/features/$FEATURE" ]; then
  TARGET="test/features/$FEATURE"
fi

echo "════════════════════════════════════════════════════════════════"
echo " Nariño Cultura · Mobile · Suite de pruebas"
echo " Objetivo: $TARGET"
echo "════════════════════════════════════════════════════════════════"
echo

flutter test "$TARGET" --reporter expanded "${COVERAGE_ARGS[@]}"
STATUS=$?

echo
echo "════════════════════════════════════════════════════════════════"
if [ $STATUS -eq 0 ]; then
  echo " ✅ Todos los tests pasaron."
else
  echo " ❌ Hay tests fallando (código de salida $STATUS)."
fi
if [ ${#COVERAGE_ARGS[@]} -gt 0 ]; then
  echo " Reporte de cobertura: coverage/lcov.info"
fi
echo "════════════════════════════════════════════════════════════════"

exit $STATUS
