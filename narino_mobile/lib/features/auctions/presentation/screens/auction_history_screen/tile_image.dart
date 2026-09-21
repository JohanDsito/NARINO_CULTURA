import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'placeholder_box.dart';

class TileImage extends StatelessWidget {
  const TileImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const PlaceholderBox();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      placeholder: (_, __) => const PlaceholderBox(),
      errorWidget: (_, __, ___) => const PlaceholderBox(),
    );
  }
}
