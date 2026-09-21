import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'fav_image_fallback.dart';

// ─── Imagen del favorito ──────────────────────────────────────────────────────

class FavImage extends StatelessWidget {
  const FavImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const FavImageFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const FavImageFallback(loading: true),
      errorWidget: (_, __, ___) => const FavImageFallback(),
    );
  }
}
