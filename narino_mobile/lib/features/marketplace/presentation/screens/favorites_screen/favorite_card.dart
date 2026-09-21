import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/favorite_model.dart';
import 'fav_image.dart';
import 'remove_button.dart';

// ─── Tarjeta de favorito ──────────────────────────────────────────────────────

class FavoriteCard extends StatelessWidget {
  const FavoriteCard({super.key, required this.fav, required this.onRemove});

  final FavoriteModel fav;
  final VoidCallback onRemove;

  String? get _badgeText {
    if (fav.isDisponible) return null;
    if (fav.isVendida) return 'Vendida';
    if (fav.isEnSubasta) return 'En subasta';
    return fav.estado;
  }

  Color _badgeBg(bool isDark, String badge) {
    if (badge == 'En subasta') {
      return isDark
          ? AppColors.indigoNoche.withValues(alpha: 0.25)
          : AppColors.indigoPalido;
    }
    return isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
  }

  Color _badgeFg(bool isDark, String badge) {
    if (badge == 'En subasta') {
      return isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    }
    return isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
  }

  String _formatPrice(double value) {
    final n = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeText;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final priceColor = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    return InkWell(
      onTap: () => context.push('/artworks/${fav.obraId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen ─────────────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FavImage(imageUrl: fav.imagenUrl),

                  // Badge de estado
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _badgeBg(isDark, badge),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.caption(
                            color: _badgeFg(isDark, badge),
                          ),
                        ),
                      ),
                    ),

                  // Botón de quitar favorito
                  Positioned(
                    top: 4,
                    right: 4,
                    child: RemoveButton(onRemove: onRemove),
                  ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fav.obraTitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fav.artistaNombre,
                    style: AppTypography.caption(color: textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fav.precio != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(fav.precio!),
                      style: AppTypography.labelSemiBold(color: priceColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
