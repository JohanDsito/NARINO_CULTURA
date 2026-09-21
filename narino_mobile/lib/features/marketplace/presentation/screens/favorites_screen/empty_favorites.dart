import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Estado vacío ──────────────────────────────────────────────────────────────

class EmptyFavorites extends StatelessWidget {
  const EmptyFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_outline, color: textMuted, size: 64),
          const SizedBox(height: 12),
          Text(
            'No tienes favoritos aún.',
            style: AppTypography.bodyMedium(color: textMuted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.go('/catalog'),
            icon: const Icon(Icons.palette_outlined, size: 16),
            label: const Text('Explorar catálogo'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
