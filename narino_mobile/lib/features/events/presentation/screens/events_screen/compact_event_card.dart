import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/event_model.dart';
import 'event_helpers.dart';

class CompactEventCard extends StatelessWidget {
  const CompactEventCard({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final color = tipoColorFromContext(context, event.tipo);

    return InkWell(
      onTap: () => context.push('/events/${event.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.tipoLabel.toUpperCase(),
                        style: AppTypography.caption(color: color).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                      if (event.esDestacado) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star,
                            color: AppColors.oroAndino, size: 12),
                      ],
                    ],
                  ),
                  Text(
                    event.nombre,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${twoDigits(event.fecha.hour)}:'
                    '${twoDigits(event.fecha.minute)} · ${event.lugar}',
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: textMuted),
          ],
        ),
      ),
    );
  }
}
