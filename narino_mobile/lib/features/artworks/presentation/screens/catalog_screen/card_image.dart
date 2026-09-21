import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';
import 'favorite_button.dart';

class CardImage extends ConsumerWidget {
  const CardImage({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    // ✅ FIX: colores del badge de estado resueltos desde el tema
    final stateBg = artwork.estado == 'en_subasta'
        ? (isDark ? AppColors.indigoDark : AppColors.indigoNoche)
        : (isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight);
    final stateFg = artwork.estado == 'en_subasta' ? Colors.white : textMuted;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagen principal
        artwork.imagenes.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: artwork.imagenes.first,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: bgSubtle,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: bgSubtle,
                  child: Icon(Icons.image_outlined, color: textMuted, size: 32),
                ),
              )
            : Container(
                color: bgSubtle,
                child: Icon(Icons.palette_outlined, color: textMuted, size: 32),
              ),

        // Badge de estado
        if (artwork.estado != 'disponible')
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stateBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                artwork.estado == 'en_subasta' ? 'En subasta' : 'Vendida',
                style: AppTypography.caption(color: stateFg),
              ),
            ),
          ),

        // Botón de favorito
        Positioned(
          top: 6,
          right: 6,
          child: FavoriteButton(artwork: artwork),
        ),
      ],
    );
  }
}
