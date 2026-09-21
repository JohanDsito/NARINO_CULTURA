import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/favorites_provider.dart';
import 'favorites_screen/favorites_body.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(favoritesProvider.notifier).loadFavorites(),
    );
  }

  Future<void> _removeFavorite(String obraId) async {
    await ref.read(favoritesProvider.notifier).toggleFavorite(obraId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Favoritos',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          if (state.favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.oroAndino.withAlpha(15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${state.favorites.length}',
                    style: AppTypography.caption(color: AppColors.oroClaro),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FavoritesBody(
        state: state,
        onRemove: _removeFavorite,
      ),
    );
  }
}
