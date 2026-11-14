import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// Tarjeta grande para "aún no hay obras" o "algo salió mal", con acción.
/// Es desplazable para que funcione el gesto de recargar.
class MisObrasMensaje extends StatelessWidget {
  const MisObrasMensaje({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final NcAccent accent;
  final String title;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 40),
        NcCard(
          child: Column(
            children: [
              NcAccentIcon(icon: icon, accent: accent, size: 64, glow: true),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySemiBold(color: nc.textPrimary)),
              const SizedBox(height: 8),
              Text(text,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: nc.textSecondary)),
              const SizedBox(height: 20),
              NcPrimaryButton(label: action, onPressed: onAction),
            ],
          ),
        ),
      ],
    );
  }
}
