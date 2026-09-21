import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/catalog_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';

import '../../../../support/test_helpers.dart';

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
}
