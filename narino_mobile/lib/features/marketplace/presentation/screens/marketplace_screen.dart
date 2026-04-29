import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../../shared/widgets/artwork_card.dart';
import '../providers/cart_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final artworksState = ref.watch(artworkProvider);
    final cartState = ref.watch(cartProvider);
    final disponibles =
        artworksState.artworks.where((a) => a.isDisponible).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Tienda',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro)
              .copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: AppColors.oroClaro),
            onPressed: () => context.push('/marketplace/favorites'),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.oroClaro,
                ),
                onPressed: () => context.push('/marketplace/cart'),
              ),
              if (cartState.itemCount > 0)
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
                        '${cartState.itemCount}',
                        style: AppTypography.caption(color: Colors.white)
                            .copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            color: AppColors.obsidiana,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arte original de Nariño',
                        style: AppTypography.displaySemiBold(
                          color: AppColors.oroClaro,
                        ).copyWith(fontSize: 16),
                      ),
                      Text(
                        'Apoya directamente a los artistas',
                        style: AppTypography.quoteItalic(
                          color: AppColors.oroClaro.withAlpha(180),
                        ).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.oroClaro,
                    side: const BorderSide(color: AppColors.oroClaro),
                  ),
                  onPressed: () => context.push('/marketplace/purchases'),
                  child: Text(
                    'Mis compras',
                    style: AppTypography.caption(color: AppColors.oroClaro),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              '${disponibles.length} obras disponibles',
              style: AppTypography.bodySmall(color: AppColors.textMutedLight),
            ),
          ),
          Expanded(
            child: artworksState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.tierraProfunda,
                    ),
                  )
                : disponibles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.textMutedLight,
                              size: 64,
                            ),
                            Text(
                              'No hay obras disponibles',
                              style: AppTypography.displaySemiBold(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: disponibles.length,
                        itemBuilder: (_, i) =>
                            ArtworkCard(artwork: disponibles[i]),
                      ),
          ),
        ],
      ),
    );
  }
}
