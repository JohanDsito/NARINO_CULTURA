import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/event_model.dart';
import 'event_helpers.dart';

class DateColumn extends StatelessWidget {
  const DateColumn({super.key, required this.event, required this.color});

  final EventModel event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final isPast = event.esPasado;
    final textColor = isPast ? textMuted : color;

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isPast ? bgSubtle : color.withValues(alpha: 0.09),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${event.fecha.day}',
            style: AppTypography.displaySemiBold(color: textColor)
                .copyWith(fontSize: 22),
          ),
          Text(
            kMeses[event.fecha.month - 1],
            style: AppTypography.caption(color: textColor),
          ),
        ],
      ),
    );
  }
}
