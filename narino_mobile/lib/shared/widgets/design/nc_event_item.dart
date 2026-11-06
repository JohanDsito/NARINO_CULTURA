import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_pressable.dart';

/// Ítem de agenda (`.event-item`): radio 16, hora en naranja 12/700,
/// título 15/600 y descripción 13 secundaria.
class NcEventItem extends StatelessWidget {
  const NcEventItem({
    super.key,
    required this.time,
    required this.title,
    this.description,
    this.onTap,
  });

  final String time;
  final String title;
  final String? description;
  final VoidCallback? onTap;

  static const _dias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  /// "HOY • 19:00", "MAÑANA • 10:00" o "SÁB 12 • 14:00".
  static String formatTime(DateTime fecha, {DateTime? now}) {
    final hoy = now ?? DateTime.now();
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    final diff = d.difference(base).inDays;
    final hora =
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    final dia = switch (diff) {
      0 => 'HOY',
      1 => 'MAÑANA',
      _ => '${_dias[fecha.weekday - 1]} ${fecha.day}',
    };
    return '$dia • $hora';
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final desc = description?.trim();
    return NcPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: '$title, $time',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: nc.itemFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: nc.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: AppTypography.eventTime(color: nc.naranjaA.ink)),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSemiBold(color: nc.textPrimary)
                  .copyWith(height: 1.3),
            ),
            if (desc != null && desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(color: nc.textSecondary)
                    .copyWith(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
