import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/profile_model.dart';
import 'funciones_proximas.dart';
import 'musician_profile_option.dart';
import 'profile_option_group.dart';
import 'profile_option_tile.dart';
import 'profile_section_title.dart';

/// "Mi contenido" (y "Mi música" si es músico): solo para artistas.
class ProfileContentSection extends StatelessWidget {
  const ProfileContentSection({
    super.key,
    required this.profile,
    required this.esMusico,
  });

  final ProfileModel? profile;
  final bool esMusico;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final portafolioPronto = kFuncionesProximas.contains('portafolio');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle('Mi contenido'),
        ProfileOptionGroup(children: [
          if (!esMusico)
            ProfileOptionTile(
              icon: Icons.palette_outlined,
              accent: nc.catalogo,
              title: 'Mis obras',
              subtitle: 'Publica, edita y subasta tus obras',
              onTap: () => context.push('/profile/my-artworks'),
            ),
          ProfileOptionTile(
            icon: Icons.collections_outlined,
            accent: nc.naranjaA,
            title: 'Mi portafolio',
            subtitle: 'Fotos y videos de tu proceso',
            proximamente: portafolioPronto,
            onTap: () => portafolioPronto
                ? avisarProximamente(context, 'El portafolio')
                : context.push('/profile/portfolio'),
          ),
          ProfileOptionTile(
            icon: Icons.trending_up_rounded,
            accent: nc.oroA,
            title: 'Mis ventas',
            subtitle: 'Lo que has vendido y cuánto has ganado',
            onTap: () => context.push('/marketplace/sales'),
          ),
          if (profile?.disciplina.trim().isNotEmpty == true)
            ProfileOptionTile(
              icon: Icons.insights_rounded,
              accent: nc.azulA,
              title: 'Mis estadísticas',
              subtitle: 'Visitas, seguidores e ingresos',
              onTap: () => context.push('/profile/stats'),
            ),
        ]),
        if (esMusico) ...[
          const ProfileSectionTitle('Mi música'),
          const ProfileOptionGroup(children: [MusicianProfileOption()]),
        ],
      ],
    );
  }
}
