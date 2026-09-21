import 'package:flutter/material.dart';

import 'empty_favorites.dart';
import 'favorite_card.dart';

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class FavoritesBody extends StatelessWidget {
  const FavoritesBody({super.key, required this.state, required this.onRemove});

  final dynamic state; // FavoritesState
  final Future<void> Function(String obraId) onRemove;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
      );
    }

    if (state.favorites.isEmpty) {
      return const EmptyFavorites();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemCount: state.favorites.length,
      itemBuilder: (context, i) => FavoriteCard(
        fav: state.favorites[i],
        onRemove: () => onRemove(state.favorites[i].obraId),
      ),
    );
  }
}
