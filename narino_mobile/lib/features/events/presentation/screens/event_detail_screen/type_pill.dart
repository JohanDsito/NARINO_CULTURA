import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class TypePill extends StatelessWidget {
  const TypePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final pillFg = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: pillFg),
      ),
    );
  }
}
