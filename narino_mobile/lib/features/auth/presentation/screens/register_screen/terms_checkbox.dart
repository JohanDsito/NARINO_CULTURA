import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.accepted,
    required this.disabled,
    required this.onChanged,
  });

  final bool accepted;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;

    return InkWell(
      onTap: disabled ? null : () => onChanged(!accepted),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accepted ? cs.primary.withValues(alpha: 0.06) : bgSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accepted ? cs.primary.withValues(alpha: 0.5) : border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: accepted,
                onChanged: disabled ? null : (v) => onChanged(v ?? false),
                activeColor: cs.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySmall(color: textSecondary),
                  children: const [
                    TextSpan(
                        text:
                            'He leído y acepto los '),
                    TextSpan(
                      text: 'Términos y Condiciones',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de Privacidad',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: ' de Nariño Cultura.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
