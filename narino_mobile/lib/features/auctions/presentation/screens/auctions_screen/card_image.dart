import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'fallback_image.dart';

class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const FallbackImage();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 78,
      height: 78,
      fit: BoxFit.cover,
      placeholder: (_, __) => const FallbackImage(loading: true),
      errorWidget: (_, __, ___) => const FallbackImage(),
    );
  }
}
