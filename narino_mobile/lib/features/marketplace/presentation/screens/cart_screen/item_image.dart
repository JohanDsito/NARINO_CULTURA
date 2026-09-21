import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'image_fallback.dart';

class ItemImage extends StatelessWidget {
  const ItemImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const ImageFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ImageFallback(loading: true),
      errorWidget: (_, __, ___) => const ImageFallback(),
    );
  }
}
