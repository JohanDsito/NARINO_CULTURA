import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';

class CardInfo extends StatelessWidget {
  const CardInfo({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            artwork.titulo,
            style: AppTypography.labelSemiBold(color: textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            artwork.artistaNombre,
            style: AppTypography.caption(color: textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          artwork.precio != null
              ? Text(
                  _formatCOP(artwork.precio!),
                  // oroAndino es intencional: color de precio es parte del branding
                  style:
                      AppTypography.labelSemiBold(color: AppColors.oroAndino),
                )
              : Text(
                  'Exhibición',
                  style: AppTypography.caption(color: textMuted),
                ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatCOP(double value) {
  final raw = value.toStringAsFixed(0);
  return '\$${raw.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}';
}
