import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../../core/theme/app_typography.dart';

// ─── Galería zoom ─────────────────────────────────────────────────────────────

class ZoomGallery extends StatefulWidget {
  const ZoomGallery({
    super.key,
    required this.images,
    required this.controller,
    required this.initialIndex,
    required this.onPageChanged,
  });

  final List<String> images;
  final PageController controller;
  final int initialIndex;
  final ValueChanged<int> onPageChanged;

  @override
  State<ZoomGallery> createState() => _ZoomGalleryState();
}

class _ZoomGalleryState extends State<ZoomGallery> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: AppTypography.labelSemiBold(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        pageController: widget.controller,
        itemCount: widget.images.length,
        builder: (_, index) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.images[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (i) {
          setState(() => _current = i);
          widget.onPageChanged(i);
        },
        loadingBuilder: (_, __) => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
