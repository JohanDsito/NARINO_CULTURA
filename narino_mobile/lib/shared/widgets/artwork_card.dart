import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/artworks/domain/artwork_model.dart';

class ArtworkCard extends StatelessWidget {
  const ArtworkCard({super.key, required this.artwork, this.compact = false});

  final ArtworkModel artwork;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageUrl = artwork.imagenes.isNotEmpty ? artwork.imagenes.first : null;

    return GestureDetector(
      onTap: () => context.go('/artworks/${artwork.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: compact ? 4 : 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.bgSubtleLight,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.borderLight,
                          size: 32,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.bgSubtleLight,
                      child: const Icon(
                        Icons.palette_outlined,
                        color: AppColors.borderLight,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: compact ? 3 : 2,
              child: Padding(
                padding: EdgeInsets.all(compact ? 8 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.titulo,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artwork.artistaNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      artwork.precio == null
                          ? 'Precio a consultar'
                          : _fmt(artwork.precio!),
                      style: (compact
                              ? AppTypography.caption(color: AppColors.indigoNoche)
                              : AppTypography.caption(color: AppColors.indigoNoche))
                          .copyWith(fontSize: compact ? 11 : null),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double value) {
    final n = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }
}
