import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/event_model.dart';
import 'badge_row.dart';
import 'date_column.dart';
import 'event_helpers.dart';
import 'meta_row.dart';

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final color = tipoColorFromContext(context, event.tipo);
    final isPast = event.esPasado;

    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isPast ? bgSubtle : bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: event.esDestacado ? AppColors.oroAndino : border,
            width: event.esDestacado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            DateColumn(event: event, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BadgeRow(event: event, color: color),
                    const SizedBox(height: 6),
                    Text(
                      event.nombre,
                      style: AppTypography.labelSemiBold(
                        color: isPast ? textMuted : textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    MetaRow(
                        icon: Icons.location_on_outlined, text: event.lugar),
                    MetaRow(
                      icon: Icons.access_time_outlined,
                      text:
                          '${twoDigits(event.fecha.hour)}:${twoDigits(event.fecha.minute)}',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
