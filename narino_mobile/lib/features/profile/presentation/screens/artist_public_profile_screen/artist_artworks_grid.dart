import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../artworks/domain/artwork_model.dart';
import '../../../../artworks/presentation/screens/catalog_screen/artwork_card.dart';

/// Obras del artista en cuadrícula de dos columnas, con carga y vacío.
class ArtistArtworksGrid extends StatelessWidget {
  const ArtistArtworksGrid({super.key, required this.obras});

  final AsyncValue<List<ArtworkModel>> obras;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return obras.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => NcBanner.error(context, 'No pudimos cargar sus obras.'),
      data: (list) => list.isEmpty
          ? NcEmptyState(
              icon: Icons.palette_outlined,
              accent: nc.catalogo,
              title: 'Aún no hay obras',
              message: 'Cuando publique, sus obras aparecerán aquí.',
              padding: EdgeInsets.zero,
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.64,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => CatalogArtworkCard(artwork: list[i]),
            ),
    );
  }
}
