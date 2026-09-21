import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Banner de seguridad ──────────────────────────────────────────────────────

class SecurityBanner extends StatelessWidget {
  const SecurityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.indigoNoche.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.indigoNoche.withAlpha(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.indigoNoche.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: AppColors.indigoNoche, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pago 100% seguro con Wompi. Tus datos de tarjeta nunca se almacenan en nuestros servidores.',
              style: AppTypography.bodySmall(color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
