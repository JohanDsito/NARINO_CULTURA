import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/nc_theme.dart';
import 'profile_option_group.dart';
import 'profile_option_tile.dart';
import 'profile_section_title.dart';

/// "Compras y actividad": compras, favoritos, seguidos y subastas.
class ProfileActivitySection extends StatelessWidget {
  const ProfileActivitySection({super.key, required this.favoritos});

  /// Cantidad de favoritos, para la insignia.
  final int favoritos;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle('Compras y actividad'),
        ProfileOptionGroup(children: [
          ProfileOptionTile(
            icon: Icons.shopping_bag_outlined,
            accent: nc.tienda,
            title: 'Mis compras',
            subtitle: 'Órdenes, pagos y comprobantes',
            onTap: () => context.push('/marketplace/purchases'),
          ),
          ProfileOptionTile(
            icon: Icons.favorite_border_rounded,
            accent: nc.magentaA,
            title: 'Mis favoritos',
            subtitle: 'Obras que guardaste',
            badge: favoritos,
            onTap: () => context.push('/marketplace/favorites'),
          ),
          ProfileOptionTile(
            icon: Icons.people_outline_rounded,
            accent: nc.azulA,
            title: 'Siguiendo',
            subtitle: 'Artistas y músicos que sigues',
            onTap: () => context.push('/profile/following'),
          ),
          ProfileOptionTile(
            icon: Icons.gavel_rounded,
            accent: nc.subastas,
            title: 'Mis subastas',
            subtitle: 'Pujas y subastas que abriste',
            onTap: () => context.push('/auctions/history'),
          ),
        ]),
      ],
    );
  }
}
