import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/artwork_model.dart';
import '../../../../marketplace/presentation/providers/favorites_provider.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.bgSubtleDark.withAlpha(230)
        : AppColors.bgSubtleLight.withAlpha(230);
    final isFav = ref.watch(favoritesProvider).isFavorite(artwork.id);
    final iconColor = isFav ? AppColors.error : cs.onSurface;
    final icon = isFav ? Icons.favorite : Icons.favorite_outline;

    return GestureDetector(
      onTap: () =>
          ref.read(favoritesProvider.notifier).toggleFavorite(artwork.id),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
