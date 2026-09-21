import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'event_meta.dart';

// ─── Tarjeta de evento ────────────────────────────────────────────────────────

class EventCard extends StatelessWidget {
  const EventCard({
    required this.title,
    required this.date,
    required this.place,
    required this.type,
    this.onTap,
    super.key,
  });

  final String title;
  final String date;
  final String place;
  final String type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final typeBg = isDark
        ? AppColors.indigoNoche.withValues(alpha: 0.25)
        : AppColors.indigoPalido;
    final typeFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    final eventIconBg = isDark
        ? AppColors.selvaAndina.withValues(alpha: 0.22)
        : AppColors.selvaPalida;
    final eventIconFg = isDark ? AppColors.selvaDark : AppColors.selvaAndina;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: eventIconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_outlined, color: eventIconFg, size: 22),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  EventMeta(icon: Icons.schedule_outlined, text: date),
                  const SizedBox(height: 2),
                  EventMeta(icon: Icons.place_outlined, text: place),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Badge de tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                type,
                style: AppTypography.caption(color: typeFg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
