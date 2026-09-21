import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'error_banner.dart';

class ForgotForm extends StatelessWidget {
  const ForgotForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recuperar contraseña',
            style: AppTypography.displaySemiBold(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña. El enlace es válido por 30 minutos.',
            style: AppTypography.bodySmall(color: textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !loading,
            style: AppTypography.bodyMedium(color: textPrimary),
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                return 'Correo no válido';
              }
              return null;
            },
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 20),
          if (error != null) ...[
            ErrorBanner(message: error!),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: cs.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Enviar enlace',
                      style: AppTypography.buttonText(color: cs.onPrimary),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver al login'),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
