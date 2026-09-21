import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Enlace de acción (p. ej. "¿No tienes cuenta? Regístrate") usado en auth.
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.enabled,
    required this.onTap,
  });

  final String question;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: AppTypography.bodySmall(color: textMuted),
        ),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Text(
            actionLabel,
            style: AppTypography.bodySmall(color: cs.primary)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
