import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../artworks/presentation/screens/catalog_screen/artwork_card.dart';
import '../../domain/marketplace_state.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';

/// Obras a la venta. Usa su propia consulta (`status=DISPONIBLE`) para no
/// reiniciar los filtros del Catálogo, que antes compartía estado.
final tiendaObrasProvider =
    FutureProvider.autoDispose<List<ArtworkModel>>((ref) async {
  return ref.read(artworkRepositoryProvider).getDisponibles();
});

/// Tienda (acento naranja: artesanos y marketplace).
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
      ref.read(cartProvider.notifier).loadCart();
      if (ref.read(favoritesProvider).status == MarketplaceStatus.initial) {
        ref.read(favoritesProvider.notifier).loadFavorites();
      }
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(tiendaObrasProvider);
    await Future.wait([
      ref.read(tiendaObrasProvider.future).catchError((_) => <ArtworkModel>[]),
      ref.read(cartProvider.notifier).loadCart(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final obras = ref.watch(tiendaObrasProvider);
    final carrito = ref.watch(cartProvider.select((s) => s.itemCount));
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final top = MediaQuery.paddingOf(context).top + NcGlassHeader.contentHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: NcGlassHeader(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ARTESANOS & MARKETPLACE',
                style: AppTypography.caption(color: nc.tienda.ink)
                    .copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text('Tienda',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
          ],
        ),
        actions: [
          NcIconButton(
            icon: Icons.favorite_border_rounded,
            tooltip: 'Favoritos',
            onPressed: () => context.push('/marketplace/favorites'),
          ),
          if (role != null)
            NcIconButton(
              icon: Icons.shopping_bag_outlined,
              tooltip: 'Carrito',
              badge: carrito,
              onPressed: () => context.push('/marketplace/cart'),
            ),
        ],
      ),
      body: RefreshIndicator(
        edgeOffset: top,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: top + 16)),
            SliverToBoxAdapter(child: _Banner(esArtista: role == 'artista')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Disponibles ahora',
                          style: AppTypography.displayBold(
                              color: nc.textPrimary)),
                    ),
                    if (obras.valueOrNull != null)
                      Text('${obras.valueOrNull!.length} obras',
                          style: AppTypography.labelMedium(
                              color: nc.textSecondary)),
                  ],
                ),
              ),
            ),
            ...obras.when(
              loading: () => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverToBoxAdapter(
                  child: NcEmptyState(
                    icon: Icons.cloud_off_rounded,
                    accent: nc.tomateA,
                    title: 'No pudimos cargar la tienda',
                    message: e.toString(),
                    actionLabel: 'Reintentar',
                    onAction: () => ref.invalidate(tiendaObrasProvider),
                  ),
                ),
              ],
              data: (list) => list.isEmpty
                  ? [
                      SliverToBoxAdapter(
                        child: NcEmptyState(
                          icon: Icons.storefront_outlined,
                          accent: nc.tienda,
                          title: 'La tienda está por abrir',
                          message: 'Aún no hay obras a la venta. Vuelve pronto '
                              'o explora el catálogo completo.',
                          actionLabel: 'Ver catálogo',
                          onAction: () => context.go('/catalog'),
                        ),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.64,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => CatalogArtworkCard(artwork: list[i]),
                            childCount: list.length,
                          ),
                        ),
                      ),
                    ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.esArtista});

  final bool esArtista;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final atajos = <(IconData, String, String, NcAccent)>[
      (Icons.receipt_long_outlined, 'Mis compras', '/marketplace/purchases',
          nc.tienda),
      (Icons.favorite_border_rounded, 'Favoritos', '/marketplace/favorites',
          nc.magentaA),
      if (esArtista)
        (Icons.trending_up_rounded, 'Mis ventas', '/marketplace/sales',
            nc.oroA),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NcCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ARTE ORIGINAL DE NARIÑO',
                style: AppTypography.kicker(color: nc.oroA.ink)),
            const SizedBox(height: 8),
            Text('Compra directo al creador',
                style: AppTypography.displayBold(color: nc.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'Cada compra apoya a artesanos, pintores y fotógrafos del '
              'departamento. Pago seguro con Wompi.',
              style: AppTypography.bodyMedium(color: nc.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in atajos)
                  NcPressable(
                    onTap: () => context.push(a.$3),
                    semanticLabel: a.$2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: a.$4.tint,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: a.$4.fill.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.$1, size: 16, color: a.$4.ink),
                          const SizedBox(width: 6),
                          Text(a.$2,
                              style: AppTypography.labelMedium(color: a.$4.ink)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
