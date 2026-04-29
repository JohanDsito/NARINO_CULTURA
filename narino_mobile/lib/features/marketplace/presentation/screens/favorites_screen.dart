import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/favorite_model.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Favoritos',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_outline,
                        color: AppColors.textMutedLight,
                        size: 64,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No tienes favoritos aún.',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context.go('/catalog'),
                        child: const Text('Ver catálogo'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: state.favorites.length,
                  itemBuilder: (context, i) => _FavoriteCard(
                    fav: state.favorites[i],
                    onRemove: () async {
                      await ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(state.favorites[i].obraId);
                    },
                  ),
                ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.fav, required this.onRemove});

  final FavoriteModel fav;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final badgeText = fav.isDisponible
        ? null
        : fav.isVendida
            ? 'Vendida'
            : fav.isEnSubasta
                ? 'En subasta'
                : fav.estado;

    return InkWell(
      onTap: () => context.push('/artworks/${fav.obraId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: fav.imagenUrl == null
                        ? Container(color: AppColors.bgSubtleLight)
                        : Image.network(
                            fav.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppColors.bgSubtleLight),
                          ),
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTypography.caption(
                              color: AppColors.textMutedLight),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      tooltip: 'Quitar',
                      onPressed: onRemove,
                      icon: const Icon(Icons.favorite),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fav.obraTitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fav.artistaNombre,
                    style:
                        AppTypography.caption(color: AppColors.textMutedLight),
                  ),
                  if (fav.precio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '\$${fav.precio!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+$)'), (m) => '${m[1]}.')} COP',
                      style: AppTypography.labelSemiBold(
                        color: AppColors.indigoNoche,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
