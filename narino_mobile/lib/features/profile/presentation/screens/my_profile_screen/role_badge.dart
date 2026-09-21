import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

// ─── Badge de tipo de cuenta ──────────────────────────────────────────────────

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final String role;

  (IconData, String, Color) get _info {
    switch (role) {
      case 'artista':
        return (Icons.palette_outlined, 'Artista', AppColors.selvaAndina);
      case 'comprador':
        return (Icons.explore_outlined, 'Visitante', AppColors.oroAndino);
      case 'gestor':
      case 'gestor_cultural':
        return (Icons.event_outlined, 'Gestor Cultural', AppColors.tierraProfunda);
      case 'admin':
        return (Icons.shield_outlined, 'Administrador', AppColors.error);
      default:
        return (Icons.person_outline, role, AppColors.oroClaro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.caption(color: color)),
        ],
      ),
    );
  }
}
