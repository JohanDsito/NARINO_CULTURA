import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../home_screen.dart';
import 'featured_artwork_tile.dart';

/// Cuántas obras destacadas pide Inicio (las más vistas).
const kHomeFeaturedLimit = 8;

/// Franja horizontal de obras destacadas. Si no hay obras, no se muestra.
class FeaturedStrip extends ConsumerWidget {
  const FeaturedStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(homeFeaturedArtworksProvider(kHomeFeaturedLimit)).valueOrNull;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NcSectionHeader(
            title: 'Obras destacadas',
            actionLabel: 'Ver todo',
            onAction: () => context.go('/catalog'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => FeaturedArtworkTile(artwork: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}
