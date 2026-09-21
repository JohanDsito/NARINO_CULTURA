import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class DuracionSlider extends StatelessWidget {
  const DuracionSlider(
      {super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  String get _label {
    if (value == 1) return '1 día';
    if (value < 7) return '$value días';
    if (value == 7) return '1 semana';
    if (value == 14) return '2 semanas';
    if (value == 30) return '1 mes';
    return '$value días';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final pillBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final pillFg = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duración',
                style: AppTypography.bodyMedium(color: textMuted),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _label,
                  style: AppTypography.caption(color: pillFg),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: cs.primary,
            inactiveColor: border,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 día', style: AppTypography.caption(color: textMuted)),
              Text('30 días', style: AppTypography.caption(color: textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
