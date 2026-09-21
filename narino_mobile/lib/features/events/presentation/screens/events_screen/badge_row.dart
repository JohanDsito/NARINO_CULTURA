import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/event_model.dart';
import 'small_badge.dart';

class BadgeRow extends StatelessWidget {
  const BadgeRow({super.key, required this.event, required this.color});

  final EventModel event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        SmallBadge(
          label: event.tipoLabel,
          bg: color.withValues(alpha: 0.12),
          fg: color,
        ),
        if (event.esDestacado) ...[
          const SizedBox(width: 6),
          SmallBadge(
            label: '⭐ Destacado',
            bg: isDark
                ? AppColors.oroAndino.withValues(alpha: 0.18)
                : AppColors.oroPalido,
            fg: isDark ? AppColors.oroDark : AppColors.oroAndino,
          ),
        ],
      ],
    );
  }
}
