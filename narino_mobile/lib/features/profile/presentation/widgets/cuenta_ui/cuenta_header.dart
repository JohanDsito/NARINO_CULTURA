import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

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
        Text(message, style: AppTypography.bodyMedium(color: nc.textSecondary)),
      ],
    );
  }
}
