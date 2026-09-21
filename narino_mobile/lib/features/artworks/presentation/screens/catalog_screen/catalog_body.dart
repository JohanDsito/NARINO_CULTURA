import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/artwork_state.dart';
import 'artwork_card.dart';
import 'empty_body.dart';
import 'error_body.dart';
import 'loading_grid.dart';

// ─── Cuerpo del catálogo ──────────────────────────────────────────────────────

class CatalogBody extends ConsumerWidget {
  const CatalogBody({super.key, required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) return const LoadingGrid();
    if (state.hasError) return ErrorBody(state: state);
    if (state.artworks.isEmpty) return EmptyBody(state: state);

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: state.artworks.length,
      itemBuilder: (context, i) =>
          CatalogArtworkCard(artwork: state.artworks[i]),
    );
  }
}
