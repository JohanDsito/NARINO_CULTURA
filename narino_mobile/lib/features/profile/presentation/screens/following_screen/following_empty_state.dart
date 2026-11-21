import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class FollowingEmptyState extends StatelessWidget {
  const FollowingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      children: [
        Center(
          child: NcAccentIcon(
              icon: Icons.favorite_border_rounded,
              accent: nc.catalogo,
              size: 72,
              glow: true),
        ),
        const SizedBox(height: 20),
        Text('Todavía no sigues a nadie',
            textAlign: TextAlign.center,
            style: AppTypography.displaySemiBold(color: nc.textPrimary)),
        const SizedBox(height: 8),
        Text(
          'Sigue a artistas y músicos de Nariño para enterarte de sus obras '
          'nuevas, subastas y conciertos.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(color: nc.textSecondary),
        ),
        const SizedBox(height: 24),
        NcPrimaryButton(
          label: 'Explorar el catálogo',
          icon: Icons.palette_outlined,
          onPressed: () => context.go('/catalog'),
        ),
        const SizedBox(height: 10),
        NcSecondaryButton(
          label: 'Descubrir música',
          icon: Icons.music_note_rounded,
          onPressed: () => context.push('/musicians'),
        ),
      ],
    );
  }
}
