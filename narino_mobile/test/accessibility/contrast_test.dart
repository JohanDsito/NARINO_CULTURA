// MO-ACC-03: contraste WCAG AA (≥ 4.5:1 para texto normal) calculado con los
// colores reales del tema, en modo claro y oscuro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/theme/app_colors.dart';
import 'package:narino_cultura/core/theme/nc_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// Compone un color con transparencia sobre su fondo, como en pantalla.
Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

void main() {
  const aa = 4.5;

  for (final nc in [NcColors.light, NcColors.dark]) {
    final modo = nc.isDark ? 'oscuro' : 'claro';
    final fondos = {
      'bg': nc.bg,
      'tarjeta': nc.bgCard,
      'bgSubtle': nc.bgSubtle,
    };

    test('textos primario, secundario y tenue sobre todos los fondos ($modo)',
        () {
      for (final f in fondos.entries) {
        for (final t in {
          'primario': nc.textPrimary,
          'secundario': nc.textSecondary,
          'tenue': nc.textMuted,
        }.entries) {
          expect(_contrast(t.value, f.value), greaterThanOrEqualTo(aa),
              reason: 'texto ${t.key} sobre ${f.key}');
        }
      }
    });

    test('texto de error de formulario sobre tarjeta y fondo ($modo)', () {
      expect(_contrast(nc.tomateA.ink, nc.bgCard), greaterThanOrEqualTo(aa));
      expect(_contrast(nc.tomateA.ink, nc.bg), greaterThanOrEqualTo(aa));
    });

    test('acción del SnackBar sobre su fondo ($modo)', () {
      // El SnackBar usa textPrimary de fondo (oscuro en claro y viceversa).
      final accion = nc.isDark ? AppColors.azulNeonLight : AppColors.azulNeon;
      expect(_contrast(accion, nc.textPrimary), greaterThanOrEqualTo(aa));
    });

    test('contador sobre íconos y textos sobre rellenos de acento ($modo)', () {
      for (final a in {
        'tomate': nc.tomateA,
        'naranja': nc.naranjaA,
        'magenta': nc.magentaA,
      }.entries) {
        expect(_contrast(a.value.onFill, a.value.fill), greaterThanOrEqualTo(aa),
            reason: 'texto sobre ${a.key}');
      }
    });

    test('tintas de acento sobre su fondo tintado ($modo)', () {
      for (final a in [nc.tomateA, nc.naranjaA, nc.magentaA, nc.oroA]) {
        expect(_contrast(a.ink, _over(a.tint, nc.bgCard)),
            greaterThanOrEqualTo(aa));
      }
    });
  }
}
