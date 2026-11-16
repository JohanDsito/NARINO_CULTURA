import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/catalog_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';

import '../../../../support/test_helpers.dart';

/// 45 obras en páginas de 20.
class _PagedRepo extends FakeArtworkRepository {
  final pedidas = <int>[];

  @override
  Future<({List<ArtworkModel> artworks, int total})> getCatalog({
    String? search,
    String? categoria,
    String? tecnica,
    double? precioMin,
    double? precioMax,
    String ordenarPor = 'fecha',
    int page = 1,
  }) async {
    pedidas.add(page);
    final desde = (page - 1) * 20;
    final hasta = (desde + 20).clamp(0, 45);
    return (
      artworks: [
        for (var i = desde; i < hasta; i++)
          testArtwork(id: '$i', titulo: 'Obra $i'),
      ],
      total: 45,
    );
  }
}

void main() {
  setUpAll(ensureApiClientInitialized);

  // MO-WT-03
  testWidgets(
      'CatalogScreen renderiza el AppBar con título "Catálogo de Obras"',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const CatalogScreen(),
        overrides: [
          artworkRepositoryProvider.overrideWithValue(FakeArtworkRepository()),
          favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
        ],
      ),
    );

    expect(find.text('Catálogo de Obras'), findsOneWidget);
  });

  // MO-LOAD-01: al bajar se cargan las páginas siguientes hasta el final.
  testWidgets('el scroll trae las páginas siguientes hasta el final',
      (WidgetTester tester) async {
    final repo = _PagedRepo();
    await tester.pumpWidget(
      wrap(
        const CatalogScreen(),
        overrides: [
          artworkRepositoryProvider.overrideWithValue(repo),
          favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('45 obras'), findsOneWidget);

    for (var i = 0;
        i < 40 && find.textContaining('Llegaste al final').evaluate().isEmpty;
        i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pump();
      await tester.pump();
    }

    expect(find.text('Llegaste al final · 45 obras'), findsOneWidget);
    expect(repo.pedidas, [1, 2, 3]);
  });
}
