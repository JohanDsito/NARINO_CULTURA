import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Fondo de portada (para obras sin miniatura).
class PortadaMusical extends StatelessWidget {
  const PortadaMusical(
      {super.key, this.url, this.icon = Icons.music_note_rounded});

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nc.musica.tint, nc.magentaA.tint],
        ),
      ),
      child: Center(child: Icon(icon, color: nc.musica.ink, size: 28)),
    );
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
