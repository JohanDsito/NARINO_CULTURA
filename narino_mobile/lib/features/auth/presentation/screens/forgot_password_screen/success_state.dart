import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class SuccessState extends StatelessWidget {
  const SuccessState({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: cs.tertiary.withAlpha(18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: cs.tertiary,
            size: 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Correo enviado!',
          style: AppTypography.displaySemiBold(color: textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Revisa tu bandeja en $email.\nEl enlace expira en 30 minutos.',
          style: AppTypography.bodyMedium(color: textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '¿No lo ves? Revisa la carpeta de spam.',
          style: AppTypography.bodySmall(color: textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_outlined),
            label: Text(
              'Volver al login',
              style: AppTypography.buttonText(color: cs.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
