import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';
import 'artwork_card.dart';
import 'catalog_skeleton_card.dart';
import 'catalog_state_message.dart';

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 14,
  childAspectRatio: 0.64,
);

/// Cuerpo del catálogo como sliver: esqueletos, error, vacío o grilla.
class CatalogBody extends ConsumerWidget {
  const CatalogBody({super.key, required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.artworks.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (_, __) => const CatalogSkeletonCard(),
            childCount: 6,
          ),
        ),
      );
    }
    if (state.hasError) {
      return SliverToBoxAdapter(
        child: CatalogStateMessage(
          icon: Icons.cloud_off_rounded,
          accent: context.nc.tomateA,
          title: 'No pudimos cargar el catálogo',
          message: state.errorMessage!,
          actionLabel: 'Reintentar',
          onAction: () => ref.read(artworkProvider.notifier).loadCatalog(),
        ),
      );
    }
    if (state.artworks.isEmpty) {
      final filtros = state.hayFiltrosActivos;
      return SliverToBoxAdapter(
        child: CatalogStateMessage(
          icon: Icons.palette_outlined,
          accent: context.nc.catalogo,
          title: filtros ? 'Nada con esos filtros' : 'Aún no hay obras',
          message: filtros
              ? 'Prueba con otra categoría o quita algunos filtros.'
              : 'Cuando los artistas publiquen, sus obras aparecerán aquí.',
          actionLabel: filtros ? 'Limpiar filtros' : null,
          onAction: filtros
              ? () => ref.read(artworkProvider.notifier).limpiarFiltros()
              : null,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (_, i) => CatalogArtworkCard(artwork: state.artworks[i]),
          childCount: state.artworks.length,
        ),
      ),
    );
  }
}
