import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/musician_model.dart';

/// Avatar con anillo: serpentina si el perfil está verificado, azul si no.
class MusicoAvatar extends StatelessWidget {
  const MusicoAvatar({super.key, required this.musician, this.radius = 28});

  final MusicianModel musician;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final inicial = musician.name.isNotEmpty
        ? musician.name.characters.first.toUpperCase()
        : '♪';
    final foto = musician.photoUrl;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: musician.isVerified
            ? SweepGradient(colors: [
                ...nc.carnavalGradient.colors,
                nc.carnavalGradient.colors.first,
              ])
            : null,
        color: musician.isVerified ? null : nc.musica.fill,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: nc.bgCard,
        backgroundImage: (foto != null && foto.isNotEmpty)
            ? CachedNetworkImageProvider(foto)
            : null,
        child: (foto == null || foto.isEmpty)
            ? Text(inicial,
                style: AppTypography.displaySemiBold(color: nc.musica.ink)
                    .copyWith(fontSize: radius * 0.8))
            : null,
      ),
    );
  }
}
