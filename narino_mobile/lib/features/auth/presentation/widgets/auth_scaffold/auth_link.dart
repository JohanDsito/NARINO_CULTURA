import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// "¿No tienes cuenta? Regístrate" — texto + enlace con área táctil de 44 px.
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
    this.enabled = true,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question,
            style: AppTypography.bodyMedium(color: nc.textSecondary)),
        TextButton(
          onPressed: enabled ? onTap : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(44, 44),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
