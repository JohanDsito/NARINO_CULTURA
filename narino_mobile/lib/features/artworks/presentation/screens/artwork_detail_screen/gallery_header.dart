import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/artwork_model.dart';
import 'image_empty.dart';
import 'image_error.dart';
import 'image_placeholder.dart';
import 'page_dots.dart';
import 'zoom_button.dart';

// ─── Galería de imágenes en AppBar ────────────────────────────────────────────

class GalleryHeader extends StatelessWidget {
  const GalleryHeader({
    super.key,
    required this.artwork,
    required this.imagenActiva,
    required this.onTap,
    required this.onDotTap,
  });

  final ArtworkModel artwork;
  final int imagenActiva;
  final VoidCallback onTap;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    final imagenes = artwork.imagenes;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onTap,
          child: imagenes.isNotEmpty
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: CachedNetworkImage(
                    key: ValueKey(imagenes[imagenActiva]),
                    imageUrl: imagenes[imagenActiva],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ImagePlaceholder(),
                    errorWidget: (_, __, ___) => const ImageError(),
                  ),
                )
              : const ImageEmpty(),
        ),

        // Gradiente superior e inferior
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC000000),
                Color(0x00000000),
                Color(0xBB000000),
              ],
              stops: [0, 0.4, 1],
            ),
          ),
        ),

        // Botón "Ver en zoom"
        Positioned(
          right: 14,
          bottom: imagenes.length > 1 ? 38 : 14,
          child: ZoomButton(onTap: onTap),
        ),

        // Indicador de páginas
        if (imagenes.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: PageDots(
              count: imagenes.length,
              activeIndex: imagenActiva,
              onTap: onDotTap,
            ),
          ),
      ],
    );
  }
}
