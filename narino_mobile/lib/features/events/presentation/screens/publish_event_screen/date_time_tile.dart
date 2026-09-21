import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Selector de fecha/hora ───────────────────────────────────────────────────

class DateTimeTile extends StatelessWidget {
  const DateTimeTile({super.key, required this.fecha, required this.onTap});

  final DateTime? fecha;
  final VoidCallback? onTap;

  String get _label {
    if (fecha == null) return 'Fecha y hora *';
    final dd = fecha!.day.toString().padLeft(2, '0');
    final mm = fecha!.month.toString().padLeft(2, '0');
    final hh = fecha!.hour.toString().padLeft(2, '0');
    final mi = fecha!.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha!.year}  ·  $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final hasValue = fecha != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? cs.primary : border,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: hasValue ? cs.primary : textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _label,
                style: AppTypography.bodyMedium(
                  color: hasValue ? textPrimary : textMuted,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }
}
