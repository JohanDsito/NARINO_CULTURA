import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/favorite_model.dart';
import '../providers/favorites_provider.dart';
import '../widgets/tienda_ui.dart';

/// Obras guardadas como favoritas (corazón magenta).
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

  Future<void> _quitar(FavoriteModel fav) async {
    await ref.read(favoritesProvider.notifier).toggleFavorite(fav.obraId);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Quitaste "${fav.obraTitulo}" de favoritos.'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () =>
              ref.read(favoritesProvider.notifier).toggleFavorite(fav.obraId),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(favoritesProvider);
    final favs = state.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text(favs.isEmpty ? 'Favoritos' : 'Favoritos · ${favs.length}'),
      ),
      body: state.isLoading && favs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : favs.isEmpty
              ? ListView(children: [
                  NcEmptyState(
                    icon: Icons.favorite_border_rounded,
                    accent: nc.magentaA,
                    title: 'Aún no guardas favoritos',
                    message: 'Toca el corazón en cualquier obra para '
                        'guardarla aquí y recibir aviso si baja de precio.',
                    actionLabel: 'Explorar el catálogo',
                    onAction: () => context.go('/catalog'),
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  ),
                ])
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(favoritesProvider.notifier).loadFavorites(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.64,
                    ),
                    itemCount: favs.length,
                    itemBuilder: (_, i) =>
                        _FavCard(fav: favs[i], onRemove: () => _quitar(favs[i])),
                  ),
                ),
    );
  }
}

class _FavCard extends StatelessWidget {
  const _FavCard({required this.fav, required this.onRemove});

  final FavoriteModel fav;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final (String? badge, NcAccent? accent) = fav.isVendida
        ? ('Vendida', nc.tomateA)
        : fav.isEnSubasta
            ? ('En subasta', nc.subastas)
            : (null, null);
    final url = fav.imagenUrl;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [nc.magentaA.tint, nc.naranjaA.tint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
          child: Icon(Icons.palette_outlined, color: nc.catalogo.ink)),
    );

    return NcPressable(
      onTap: () => context.push('/artworks/${fav.obraId}'),
      pressedScale: 0.97,
      semanticLabel: fav.obraTitulo,
      child: Container(
        decoration: BoxDecoration(
          color: nc.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: nc.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null && url.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => fallback,
                      errorWidget: (_, __, ___) => fallback,
                    )
                  else
                    fallback,
                  if (badge != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: NcStatusPill(
                          label: badge, accent: accent!, filled: true),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Semantics(
                      button: true,
                      label: 'Quitar de favoritos',
                      excludeSemantics: true,
                      child: NcPressable(
                        onTap: onRemove,
                        pressedScale: 0.85,
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 40,
                              height: 40,
                              color: Colors.black.withValues(alpha: 0.32),
                              child: Icon(Icons.favorite_rounded,
                                  size: 20, color: nc.magenta),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fav.obraTitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)
                          .copyWith(fontSize: 14)),
                  if (fav.artistaNombre.isNotEmpty)
                    Text(fav.artistaNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    fav.precio != null && fav.precio! > 0
                        ? formatCOP(fav.precio!)
                        : 'En exhibición',
                    style: fav.precio != null && fav.precio! > 0
                        ? AppTypography.labelSemiBold(color: nc.tienda.ink)
                            .copyWith(fontWeight: FontWeight.w800, fontSize: 14)
                        : AppTypography.bodySmall(color: nc.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
