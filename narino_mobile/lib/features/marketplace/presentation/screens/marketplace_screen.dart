import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../providers/cart_provider.dart';
import 'marketplace_screen/cart_badge.dart';
import 'marketplace_screen/marketplace_banner.dart';
import 'marketplace_screen/marketplace_body.dart';
import 'marketplace_screen/results_count.dart';

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
    final role = ref.watch(currentUserRoleProvider).value;
    final canBuy = role != null;
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
          if (canBuy) CartBadge(itemCount: cartState.itemCount),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MarketplaceBanner(),
          ResultsCount(count: disponibles.length),
          Expanded(
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: _refresh,
              child: MarketplaceBody(
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
