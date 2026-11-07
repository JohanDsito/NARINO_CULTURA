import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';

/// Encabezado de las pantallas de cuenta (contraseña, eliminar cuenta…):
/// ícono con el color del tema, título y una explicación corta.
class CuentaHeader extends StatelessWidget {
  const CuentaHeader({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final NcAccent accent;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NcAccentIcon(icon: icon, accent: accent, size: 56, glow: true),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(title,
              style: AppTypography.displayBold(color: nc.textPrimary)
                  .copyWith(fontSize: 24)),
        ),
        const SizedBox(height: 6),
        Text(message,
            style: AppTypography.bodyMedium(color: nc.textSecondary)),
      ],
    );
  }
}

/// Punto de una lista con ícono de color.
class CuentaPunto extends StatelessWidget {
  const CuentaPunto({
    super.key,
    required this.icon,
    required this.accent,
    required this.text,
  });

  final IconData icon;
  final NcAccent accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTypography.bodyMedium(color: nc.textPrimary)),
          ),
        ],
      ),
    );
  }
}
