import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'image_error.dart';
import 'image_placeholder.dart';

class AuctionImage extends StatelessWidget {
  const AuctionImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ImagePlaceholder(height: 220),
              errorWidget: (_, __, ___) => const ImageError(height: 220),
            )
          : const ImageError(height: 220),
    );
  }
}
