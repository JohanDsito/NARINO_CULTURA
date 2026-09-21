import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class AiButton extends StatelessWidget {
  const AiButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiColor = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;

    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: aiColor,
          side: BorderSide(color: aiColor, width: 1.5),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: aiColor,
                ),
              )
            : Text(
                label,
                style: AppTypography.labelSemiBold(color: aiColor),
              ),
      ),
    );
  }
}
