import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class PolicyContactChannel extends StatelessWidget {
  const PolicyContactChannel({
    super.key,
    required this.icon,
    required this.accent,
    required this.titulo,
    required this.texto,
    this.onTap,
  });

  final IconData icon;
  final NcAccent accent;
  final String titulo;
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fila = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NcAccentIcon(icon: icon, accent: accent, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                const SizedBox(height: 2),
                Text(texto,
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
              ],
            ),
          ),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.chevron_right_rounded, color: nc.textMuted),
            ),
        ],
      ),
    );
    if (onTap == null) return fila;
    return Semantics(
      button: true,
      label: titulo,
      child: NcPressable(onTap: onTap, pressedScale: 0.98, child: fila),
    );
  }
}
