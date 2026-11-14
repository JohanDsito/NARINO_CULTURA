import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Foto del artista con anillo de serpentina; la inicial si no hay foto.
class ArtistAvatar extends StatelessWidget {
  const ArtistAvatar({super.key, required this.nombre, this.fotoUrl});

  final String nombre;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final foto = fotoUrl;
    final tieneFoto = foto != null && foto.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [
          ...nc.carnavalGradient.colors,
          nc.carnavalGradient.colors.first,
        ]),
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: nc.bgCard,
        backgroundImage: tieneFoto ? CachedNetworkImageProvider(foto) : null,
        child: tieneFoto
            ? null
            : Text(
                nombre.isNotEmpty ? nombre.characters.first.toUpperCase() : '?',
                style: AppTypography.displayBold(color: nc.catalogo.ink)
                    .copyWith(fontSize: 30)),
      ),
    );
  }
}
