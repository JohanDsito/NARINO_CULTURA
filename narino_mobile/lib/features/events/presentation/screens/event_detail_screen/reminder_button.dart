import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Botón de recordatorio ────────────────────────────────────────────────────

class ReminderButton extends StatelessWidget {
  const ReminderButton({
    super.key,
    required this.subscribed,
    required this.loading,
    required this.onPressed,
  });

  final bool subscribed;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: subscribed
              ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.bgSubtleDark
                  : AppColors.bgSubtleLight)
              : Theme.of(context).colorScheme.primary,
          foregroundColor: subscribed
              ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight)
              : Colors.white,
          elevation: subscribed ? 0 : 2,
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                subscribed
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_outlined,
                size: 20,
              ),
        label: Text(
          subscribed ? 'Cancelar recordatorio' : 'Recordarme',
          style: AppTypography.buttonText(),
        ),
      ),
    );
  }
}
