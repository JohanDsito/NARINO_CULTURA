import 'package:flutter/material.dart';

import '../../../../artworks/domain/artwork_model.dart';
import '../home_screen.dart';
import 'artwork_card_shell.dart';

class ArtworkCardReal extends StatelessWidget {
  const ArtworkCardReal({required this.artwork, required this.onTap, super.key});

  final ArtworkModel artwork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArtworkCardShell(
      title: artwork.titulo,
      artist: artwork.artistaNombre,
      price: artwork.precio == null
          ? 'Precio a consultar'
          : formatCOP(artwork.precio!),
      imageUrl: artwork.imagenes.isNotEmpty ? artwork.imagenes.first : null,
      onTap: onTap,
    );
  }
}
