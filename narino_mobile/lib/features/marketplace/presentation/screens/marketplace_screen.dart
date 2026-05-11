import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../../shared/widgets/artwork_card.dart';
import '../providers/cart_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artworkProvider.notifier).loadCatalog(resetFiltros: true);
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  Future<void> _refresh() async {
    await ref.read(artworkProvider.notifier).loadCatalog(resetFiltros: true);
    await ref.read(cartProvider.notifier).loadCart();
  }

  @override
  Widget build(BuildContext context) {
    final artworksState = ref.watch(artworkProvider);
    final cartState = ref.watch(cartProvider);
    final disponibles =
        artworksState.artworks.where((a) => a.isDisponible).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Tienda',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: AppColors.oroClaro),
            tooltip: 'Favoritos',
            onPressed: () => context.push('/marketplace/favorites'),
          ),
          _CartBadge(itemCount: cartState.itemCount),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MarketplaceBanner(),
          _ResultsCount(count: disponibles.length),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.tierraProfunda,
              onRefresh: _refresh,
              child: _MarketplaceBody(
                artworksState: artworksState,
                disponibles: disponibles,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge del carrito ────────────────────────────────────────────────────────

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined,
              color: AppColors.oroClaro),
          tooltip: 'Carrito',
          onPressed: () => context.push('/marketplace/cart'),
        ),
        if (itemCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  itemCount > 99 ? '99+' : '$itemCount',
                  style: AppTypography.caption(
                    color: Theme.of(context).colorScheme.onError,
                  ).copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Banner superior ──────────────────────────────────────────────────────────

class _MarketplaceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      color: AppColors.obsidiana,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arte original de Nariño',
                  style:
                      AppTypography.displaySemiBold(color: AppColors.oroClaro),
                ),
                const SizedBox(height: 3),
                Text(
                  'Apoya directamente a los artistas',
                  style: AppTypography.quoteItalic(
                    color: AppColors.oroClaro.withOpacity(0.70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.oroClaro,
              side: const BorderSide(color: AppColors.oroClaro),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => context.push('/marketplace/purchases'),
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: Text(
              'Mis compras',
              style: AppTypography.caption(color: AppColors.oroClaro),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contador de resultados ───────────────────────────────────────────────────

class _ResultsCount extends StatelessWidget {
  const _ResultsCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        '$count obras disponibles',
        style: AppTypography.bodySmall(color: textMuted),
      ),
    );
  }
}

// ─── Cuerpo del catálogo ──────────────────────────────────────────────────────

class _MarketplaceBody extends StatelessWidget {
  const _MarketplaceBody({
    required this.artworksState,
    required this.disponibles,
  });

  final dynamic artworksState;
  final List<dynamic> disponibles;

  @override
  Widget build(BuildContext context) {
    if (artworksState.isLoading) {
      return const _LoadingBody();
    }

    if (disponibles.isEmpty) {
      return const _EmptyBody();
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

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 140),
        Center(
          child: CircularProgressIndicator(
            color: cs.primary,
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(Icons.storefront_outlined, color: textMuted, size: 64),
        ),
        const SizedBox(height: 14),
        Text(
          'No hay obras disponibles',
          style: AppTypography.bodyMedium(color: textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
