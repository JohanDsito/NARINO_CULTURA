import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// Botón de cerrar sesión y firma al final del perfil.
class ProfileLogoutFooter extends StatelessWidget {
  const ProfileLogoutFooter({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: nc.tomateA.ink,
            side: BorderSide(color: nc.tomateA.fill.withValues(alpha: 0.6)),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 16),
        const Center(child: NcSerpentina(width: 48)),
        const SizedBox(height: 8),
        Center(
          child: Text('Nariño Cultura · hecho con amor en Nariño',
              style: AppTypography.bodySmall(color: nc.textMuted)),
        ),
      ],
    );
  }
}
