import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/auction_model.dart';
import 'tile_image.dart';

// ─── Tile de subasta ──────────────────────────────────────────────────────────

class AuctionTile extends StatelessWidget {
  const AuctionTile({super.key, required this.auction});

  final AuctionModel auction;

  Color _estadoBg(String estado, bool isDark) => switch (estado) {
        'activa' => isDark
            ? AppColors.indigoNoche.withValues(alpha: 0.25)
            : AppColors.indigoPalido,
        'cerrada' =>
          isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida,
        _ => isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
      };

  Color _estadoFg(String estado, bool isDark) => switch (estado) {
        'activa' => isDark ? AppColors.indigoDark : AppColors.indigoNoche,
        'cerrada' => isDark ? AppColors.tierraDark : AppColors.tierraProfunda,
        _ => isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      };

  String _estadoLabel(String estado) => switch (estado) {
        'activa' => 'Activa',
        'cerrada' => 'Cerrada',
        'cancelada' => 'Cancelada',
        _ => estado,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    final estado = auction.estado;

    return InkWell(
      onTap: () => context.push('/auctions/${auction.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TileImage(imageUrl: auction.imagenUrl),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.obraTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _estadoBg(estado, isDark),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          _estadoLabel(estado),
                          style: AppTypography.caption(
                              color: _estadoFg(estado, isDark)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${auction.totalPujas} pujas',
                        style: AppTypography.caption(color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${auction.precioActual.toStringAsFixed(0)}',
                    style:
                        AppTypography.labelSemiBold(color: AppColors.oroAndino),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
