import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Banner superior ──────────────────────────────────────────────────────────

class MarketplaceBanner extends StatelessWidget {
  const MarketplaceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      color: AppColors.obsidiana,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arte original de Nariño',
                  style:
                      AppTypography.displaySemiBold(color: AppColors.oroClaro),
                ),
                const SizedBox(height: 3),
                Text(
                  'Apoya directamente a los artistas',
                  style: AppTypography.quoteItalic(
                    color: AppColors.oroClaro.withAlpha(70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.oroClaro,
              side: const BorderSide(color: AppColors.oroClaro),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => context.push('/marketplace/purchases'),
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: Text(
              'Mis compras',
              style: AppTypography.caption(color: AppColors.oroClaro),
            ),
          ),
        ],
      ),
    );
  }
}
