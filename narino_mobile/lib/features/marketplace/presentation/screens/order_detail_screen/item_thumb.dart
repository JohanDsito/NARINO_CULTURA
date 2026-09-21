import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'thumb_fallback.dart';

// ─── Miniatura del ítem ───────────────────────────────────────────────────────

class ItemThumb extends StatelessWidget {
  const ItemThumb({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const ThumbFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ThumbFallback(loading: true),
      errorWidget: (_, __, ___) => const ThumbFallback(),
    );
  }
}
