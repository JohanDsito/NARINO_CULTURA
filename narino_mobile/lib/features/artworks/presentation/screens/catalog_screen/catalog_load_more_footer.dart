import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/artwork_state.dart';
import '../../providers/artwork_provider.dart';

/// Pie del catálogo: cargando la página siguiente, error con Reintentar o
/// aviso de que no hay más obras (MO-LOAD-01).
class CatalogLoadMoreFooter extends ConsumerWidget {
  const CatalogLoadMoreFooter({super.key, required this.state});

  final ArtworkState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    if (state.status != ArtworkStatus.loaded || state.artworks.isEmpty) {
      return const SizedBox.shrink();
    }

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            Text(
              'No se pudieron cargar más obras. ${state.loadMoreError}',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: nc.textSecondary),
            ),
            TextButton(
              onPressed: () => ref.read(artworkProvider.notifier).loadMore(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (!state.hasMore && state.page > 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          'Llegaste al final · ${state.totalResultados} obras',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(color: nc.textMuted),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
