import 'package:flutter/material.dart';

import '../../../../../shared/widgets/artwork_card.dart';
import 'empty_body.dart';
import 'loading_body.dart';

// ─── Cuerpo del catálogo ──────────────────────────────────────────────────────

class MarketplaceBody extends StatelessWidget {
  const MarketplaceBody({
    super.key,
    required this.artworksState,
    required this.disponibles,
  });

  final dynamic artworksState;
  final List<dynamic> disponibles;

  @override
  Widget build(BuildContext context) {
    if (artworksState.isLoading) {
      return const LoadingBody();
    }

    if (disponibles.isEmpty) {
      return const EmptyBody();
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: disponibles.length,
      itemBuilder: (_, i) => ArtworkCard(artwork: disponibles[i]),
    );
  }
}
