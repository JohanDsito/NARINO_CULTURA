import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

const kMeses = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

Color tipoColorForBrightness(Brightness brightness, String tipo) {
  final isDark = brightness == Brightness.dark;
  final colors = <String, Color>{
    'concierto': isDark ? AppColors.tierraDark : AppColors.tierraProfunda,
    'exposicion': isDark ? AppColors.oroDark : AppColors.oroAndino,
    'taller': isDark ? AppColors.indigoDark : AppColors.indigoNoche,
    'feria': isDark ? AppColors.selvaDark : AppColors.selvaAndina,
    'convocatoria': AppColors.error,
  };
  return colors[tipo] ??
      (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);
}

Color tipoColorFromContext(BuildContext context, String tipo) =>
    tipoColorForBrightness(Theme.of(context).brightness, tipo);

String twoDigits(int v) => v.toString().padLeft(2, '0');
