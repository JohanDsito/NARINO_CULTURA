import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/favorite_model.dart';
import '../providers/favorites_provider.dart';

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

  Future<void> _removeFavorite(int obraId) async {
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
      body: _FavoritesBody(
        state: state,
        onRemove: _removeFavorite,
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({required this.state, required this.onRemove});

  final dynamic state; // FavoritesState
  final Future<void> Function(int obraId) onRemove;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
      );
    }

    if (state.favorites.isEmpty) {
      return _EmptyFavorites();
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
      itemBuilder: (context, i) => _FavoriteCard(
        fav: state.favorites[i],
        onRemove: () => onRemove(state.favorites[i].obraId),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_outline, color: textMuted, size: 64),
          const SizedBox(height: 12),
          Text(
            'No tienes favoritos aún.',
            style: AppTypography.bodyMedium(color: textMuted),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.go('/catalog'),
            icon: const Icon(Icons.palette_outlined, size: 16),
            label: const Text('Explorar catálogo'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de favorito ──────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.fav, required this.onRemove});

  final FavoriteModel fav;
  final VoidCallback onRemove;

  String? get _badgeText {
    if (fav.isDisponible) return null;
    if (fav.isVendida) return 'Vendida';
    if (fav.isEnSubasta) return 'En subasta';
    return fav.estado;
  }

  Color _badgeBg(bool isDark, String badge) {
    if (badge == 'En subasta') {
      return isDark
          ? AppColors.indigoNoche.withValues(alpha: 0.25)
          : AppColors.indigoPalido;
    }
    return isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
  }

  Color _badgeFg(bool isDark, String badge) {
    if (badge == 'En subasta') {
      return isDark ? AppColors.indigoDark : AppColors.indigoNoche;
    }
    return isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
  }

  String _formatPrice(double value) {
    final n = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '\$$n COP';
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeText;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? theme.colorScheme.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final priceColor = isDark ? AppColors.indigoDark : AppColors.indigoNoche;

    return InkWell(
      onTap: () => context.push('/artworks/${fav.obraId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen ─────────────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _FavImage(imageUrl: fav.imagenUrl),

                  // Badge de estado
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _badgeBg(isDark, badge),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.caption(
                            color: _badgeFg(isDark, badge),
                          ),
                        ),
                      ),
                    ),

                  // Botón de quitar favorito
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _RemoveButton(onRemove: onRemove),
                  ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fav.obraTitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fav.artistaNombre,
                    style: AppTypography.caption(color: textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fav.precio != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(fav.precio!),
                      style: AppTypography.labelSemiBold(color: priceColor),
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

// ─── Imagen del favorito ──────────────────────────────────────────────────────

class _FavImage extends StatelessWidget {
  const _FavImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const _FavImageFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const _FavImageFallback(loading: true),
      errorWidget: (_, __, ___) => const _FavImageFallback(),
    );
  }
}

class _FavImageFallback extends StatelessWidget {
  const _FavImageFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      color: bgSubtle,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.image_outlined, color: textMuted),
      ),
    );
  }
}

// ─── Botón de quitar favorito ─────────────────────────────────────────────────

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.bgCardDark.withValues(alpha: 0.92)
        : Colors.white.withAlpha(92);
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite,
          color: AppColors.error,
          size: 17,
        ),
      ),
    );
  }
}
