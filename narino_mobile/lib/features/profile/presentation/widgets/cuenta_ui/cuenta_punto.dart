import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

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
