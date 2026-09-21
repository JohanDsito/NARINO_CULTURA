import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/auction_model.dart';
import 'card_image.dart';

class AuctionCard extends StatelessWidget {
  const AuctionCard({super.key, required this.auction, required this.now});

  final AuctionModel auction;
  final DateTime now;

  Duration get _remaining {
    final diff = auction.fechaCierre.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatRemaining(Duration d) {
    if (d.inDays >= 1) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    final h = d.inHours.remainder(24).toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  ({Color bg, Color fg}) _badgeColors(String estado, bool isDark) =>
      estado == 'activa'
          ? (
              bg: isDark
                  ? AppColors.indigoNoche.withValues(alpha: 0.25)
                  : AppColors.indigoPalido,
              fg: isDark ? AppColors.indigoDark : AppColors.indigoNoche
            )
          : (
              bg: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
              fg: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight
            );

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
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final remaining = _remaining;
    final price =
        auction.totalPujas > 0 ? auction.precioActual : auction.precioBase;
    final colors = _badgeColors(auction.estado, isDark);
    final isUrgent = remaining.inMinutes < 60 && auction.estado == 'activa';

    return InkWell(
      onTap: () => context.push('/auctions/${auction.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.35)
                : border,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CardImage(imageUrl: auction.imagenUrl),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          auction.obraTitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.labelSemiBold(color: textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          auction.estado.toUpperCase(),
                          style: AppTypography.caption(color: colors.fg),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    auction.artistaNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: textMuted),
                  ),
                  const SizedBox(height: 10),

                  // Precio + tiempo
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${price.toStringAsFixed(0)}',
                          style: AppTypography.labelSemiBold(color: cs.primary),
                        ),
                      ),
                      Icon(
                        isUrgent
                            ? Icons.timer_outlined
                            : Icons.schedule_outlined,
                        size: 15,
                        color: isUrgent ? AppColors.error : textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRemaining(remaining),
                        style: AppTypography.caption(
                          color: isUrgent ? AppColors.error : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
