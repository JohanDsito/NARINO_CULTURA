import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home_screen.dart';
import 'artwork_card_mock.dart';
import 'artwork_card_real.dart';

// ─── Obras destacadas ─────────────────────────────────────────────────────────

class FeaturedArtworks extends StatelessWidget {
  const FeaturedArtworks({required this.ref, super.key});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncFeatured = ref.watch(homeFeaturedArtworksProvider(4));
    final items = asyncFeatured.valueOrNull;
    final useMock = items == null || items.isEmpty;
    final count = useMock ? mockArtworks.length : items.length;

    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (useMock) {
            return ArtworkCardMock(data: mockArtworks[i]);
          }
          return ArtworkCardReal(
            artwork: items[i],
            onTap: () => context.push('/artworks/${items[i].id}'),
          );
        },
      ),
    );
  }
}
