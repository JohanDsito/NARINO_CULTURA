import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class DescubrirBanner extends StatelessWidget {
  const DescubrirBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          NcAccentIcon(
              icon: Icons.auto_awesome_rounded,
              accent: nc.musica,
              size: 52,
              glow: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descubre tu sonido',
                    style: AppTypography.displaySemiBold(color: nc.textPrimary)
                        .copyWith(fontSize: 17)),
                const SizedBox(height: 2),
                Text(
                    'Cuéntanos qué quieres escuchar y te recomendamos '
                    'artistas de Nariño.',
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: nc.musica.ink),
        ],
      ),
    );
  }
}
