import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class AuctionBanner extends StatelessWidget {
  const AuctionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark
        ? AppColors.indigoNoche.withValues(alpha: 0.25)
        : AppColors.indigoPalido;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final indigoFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel_outlined, color: indigoFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta obra está en subasta. Revisa el estado de la puja en el módulo de Subastas.',
              style: AppTypography.bodySmall(color: indigoFg),
            ),
          ),
        ],
      ),
    );
  }
}
