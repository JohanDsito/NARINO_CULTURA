import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/favorite_model.dart';
import '../providers/favorites_provider.dart';
import 'favorites_screen/favorite_card.dart';

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
    // Si falló, el aviso global ya lo dijo y la obra volvió a la lista.
    if (!mounted || ref.read(favoritesProvider).isFavorite(fav.obraId)) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Quitaste "${fav.obraTitulo}" de favoritos.'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => ref
              .read(favoritesProvider.notifier)
              .toggleFavorite(fav.obraId, favorito: fav),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(favoritesProvider);
    // Las que se están quitando desaparecen al instante (optimista).
    final favs =
        state.favorites.where((f) => state.isFavorite(f.obraId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(favs.isEmpty ? 'Favoritos' : 'Favoritos · ${favs.length}'),
      ),
      body: state.isLoading && favs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.hasError && favs.isEmpty
              // Antes un error de carga decía "Aún no guardas favoritos".
              ? ListView(children: [
                  NcEmptyState(
                    icon: Icons.cloud_off_rounded,
                    accent: nc.tomateA,
                    title: 'No pudimos cargar tus favoritos',
                    message: state.errorMessage ?? '',
                    actionLabel: 'Reintentar',
                    onAction: () =>
                        ref.read(favoritesProvider.notifier).loadFavorites(),
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  ),
                ])
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
                    gridDelegate: ncArtworkGridDelegate,
                    itemCount: favs.length,
                    itemBuilder: (_, i) => FavoriteCard(
                        fav: favs[i], onRemove: () => _quitar(favs[i])),
                  ),
                ),
    );
  }
}
