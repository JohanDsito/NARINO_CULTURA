import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'stat_column.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.precioActual,
    required this.totalPujas,
    required this.remaining,
    required this.estado,
  });

  final double precioActual;
  final int totalPujas;
  final Duration remaining;
  final String estado;

  static String _formatRemaining(Duration d) {
    final h = (d.inSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((d.inSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get _isUrgent => estado == 'activa' && remaining.inMinutes < 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: StatColumn(
              label: 'Precio actual',
              labelColor: textMuted,
              value: '\$${precioActual.toStringAsFixed(0)}',
              valueStyle: AppTypography.displaySemiBold(color: textPrimary),
            ),
          ),
          Container(width: 1, height: 56, color: border),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatColumn(
                  label: 'Pujas',
                  labelColor: textMuted,
                  value: '$totalPujas',
                  valueStyle: AppTypography.labelSemiBold(color: textPrimary),
                ),
                const SizedBox(height: 12),
                StatColumn(
                  label: 'Tiempo restante',
                  labelColor: textMuted,
                  value: estado == 'activa'
                      ? _formatRemaining(remaining)
                      : '--:--:--',
                  valueStyle: AppTypography.bodyMedium(
                    color: _isUrgent ? AppColors.error : textSecondary,
                  ),
                  icon: _isUrgent
                      ? const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.error)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
