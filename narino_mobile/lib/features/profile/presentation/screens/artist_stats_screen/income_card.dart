import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class IncomeCard extends StatelessWidget {
  const IncomeCard({super.key, required this.value, required this.onGoSales});

  final String value;
  final VoidCallback onGoSales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresos del mes',
                  style: AppTypography.caption(color: textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTypography.price(color: cs.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onGoSales,
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: border),
            ),
            child: Text(
              'Ver detalle',
              style: AppTypography.labelSemiBold(
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
