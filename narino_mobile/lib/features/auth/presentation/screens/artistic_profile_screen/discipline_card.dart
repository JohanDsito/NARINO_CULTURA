import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'discipline.dart';

/// Tarjeta seleccionable que representa una disciplina artística.
class DisciplineCard extends StatelessWidget {
  const DisciplineCard({
    super.key,
    required this.discipline,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final Discipline discipline;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final selectedBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.12)
                    : (isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                discipline.icon,
                size: 24,
                color: isSelected ? cs.primary : textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discipline.label,
                    style: AppTypography.labelSemiBold(
                      color: isSelected ? cs.primary : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    discipline.description,
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.check_circle, color: cs.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
