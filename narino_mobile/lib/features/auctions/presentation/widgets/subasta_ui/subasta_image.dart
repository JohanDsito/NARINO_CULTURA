import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Imagen de la obra subastada con respaldo dorado.
class SubastaImage extends StatelessWidget {
  const SubastaImage({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nc.oroA.tint, nc.tomateA.tint],
        ),
      ),
      child: Center(
        child: Icon(Icons.gavel_rounded, size: 40, color: nc.subastas.ink),
      ),
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
