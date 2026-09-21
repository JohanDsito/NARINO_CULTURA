import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/artwork_model.dart';
import 'pill.dart';

class HeaderRow extends StatelessWidget {
  const HeaderRow({
    super.key,
    required this.artwork,
    required this.esFavorito,
    required this.favScale,
    required this.onFavTap,
  });

  final ArtworkModel artwork;
  final bool esFavorito;
  final Animation<double> favScale;
  final VoidCallback onFavTap;

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
    final pillTierraBg =
        isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final pillTierraFg = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;
    final pillIndigoBg =
        isDark ? AppColors.indigoNoche.withValues(alpha: 0.25) : AppColors.indigoPalido;
    final pillIndigoFg =
        isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    final pillMutedBg =
        isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill(
                    label: artwork.categoria,
                    background: pillTierraBg,
                    foreground: pillTierraFg,
                  ),
                  if (artwork.estado != 'disponible')
                    Pill(
                      label: artwork.estado == 'en_subasta'
                          ? 'En subasta'
                          : 'Vendida',
                      background: artwork.estado == 'en_subasta'
                          ? pillIndigoBg
                          : pillMutedBg,
                      foreground: artwork.estado == 'en_subasta'
                          ? pillIndigoFg
                          : textMuted,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, color: textMuted, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    '${artwork.viewsCount}',
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFavTap,
              child: ScaleTransition(
                scale: favScale,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: esFavorito
                        ? Colors.red.withAlpha(18)
                        : bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: esFavorito
                          ? Colors.red.shade200
                          : border,
                    ),
                  ),
                  child: Icon(
                    esFavorito ? Icons.favorite : Icons.favorite_outline,
                    color: esFavorito ? Colors.red : textMuted,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          artwork.titulo,
          style: AppTypography.displaySemiBold(color: textPrimary),
        ),
        const SizedBox(height: 6),
        if (artwork.precio != null)
          Text(
            '${_formatCOP(artwork.precio!)} COP',
            style: AppTypography.labelSemiBold(color: AppColors.oroAndino),
          )
        else
          Text(
            'Obra para exhibición — sin precio',
            style: AppTypography.bodyMedium(color: textMuted),
          ),
      ],
    );
  }
}

String _formatCOP(double value) {
  final raw = value.toStringAsFixed(0);
  return '\$${raw.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
