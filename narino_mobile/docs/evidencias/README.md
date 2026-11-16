# Evidencias de los casos de prueba MO-*

Capturas de la app (390 dp, salvo donde se indica) generadas con
`test/_preview/evidencias_preview_test.dart` y las pruebas de captura de catálogo y tienda.
Se usan en los comentarios de los issues de GitHub.

Para regenerarlas:

```bash
flutter test test/_preview/evidencias_preview_test.dart \
  --dart-define=OUT=<carpeta> --dart-define=FONTS=<carpeta con Inter-300…800.ttf> \
  --dart-define=ICONS=<flutter>/bin/cache/artifacts/material_fonts/materialicons-regular.otf
```

| Captura | Issue | Qué muestra |
|---|---|---|
| `ev_inicio_sin_conexion_*` | #125 MO-DISP-01 | Inicio sin red: aviso con el motivo y Reintentar |
| `ev_login_tiempo_agotado_*` | #127 MO-DISP-03 | "El servidor tardó demasiado…" en vez de un error genérico |
| `ev_login_credenciales_*` | #133 MO-USA-02 | Credenciales incorrectas con el siguiente paso |
| `ev_login_validacion_*` | #123 MO-ACC-03 | Errores de formulario con contraste AA en claro y oscuro |
| `ev_login_sesion_expirada_*` | #140 MO-SEG-04 | Llegada automática al login con "Tu sesión expiró" |
| `ev_favoritos_error_*` | #76 | Favoritos sin red: motivo y Reintentar (antes "Aún no guardas favoritos") |
| `ev_favoritos_claro` | #76 | Lista de favoritos |
| `ev_catalogo_final_*` | #130 MO-LOAD-01 | Scroll infinito hasta "Llegaste al final · 26 obras" |
| `ev_catalogo_360_claro` / `ev_catalogo_768_claro` / `ev_tienda_768_claro` | #136 MO-COMP-03 | 2 columnas en teléfono, 3 en tablet |
| `ev_catalogo_*`, `ev_detalle_obra_claro` | #121 #122 #124 | Corazones y botones con área de 48×48 |
| `ev_publicar_claro`, `ev_carrito_claro`, `ev_tienda_claro`, `ev_pagar_claro` | #119 #120 #132 | Pantallas de los recorridos a probar en celular |
