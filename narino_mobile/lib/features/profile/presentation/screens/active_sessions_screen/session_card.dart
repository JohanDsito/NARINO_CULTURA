import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/account_security_repository.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.onClose,
    required this.dateText,
    required this.timeText,
  });

  final ActiveSessionModel session;
  final VoidCallback? onClose;
  final String dateText;
  final String timeText;

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
    final currentBg = isDark
        ? AppColors.indigoNoche.withValues(alpha: 0.25)
        : AppColors.indigoPalido;
    final currentFg = isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.device,
                  style: AppTypography.labelSemiBold(
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (session.isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ACTUAL',
                    style: AppTypography.caption(color: currentFg),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 18, color: textMuted),
              const SizedBox(width: 6),
              Text(
                dateText,
                style: AppTypography.bodyMedium(
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Icon(Icons.schedule_outlined, size: 18, color: textMuted),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: AppTypography.bodyMedium(
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: onClose == null ? border : AppColors.error,
                ),
              ),
              child: Text(
                onClose == null ? 'Sesión actual' : 'Cerrar esta sesión',
                style: AppTypography.labelSemiBold(
                  color: onClose == null ? textMuted : AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
