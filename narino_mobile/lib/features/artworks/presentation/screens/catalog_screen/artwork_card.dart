import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/artwork_model.dart';
import 'card_image.dart';
import 'card_info.dart';

// ─── Tarjeta de obra ──────────────────────────────────────────────────────────

class CatalogArtworkCard extends ConsumerWidget {
  const CatalogArtworkCard({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: () => context.push('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: CardImage(artwork: artwork)),
            Expanded(flex: 2, child: CardInfo(artwork: artwork)),
          ],
        ),
      ),
    );
  }
}
