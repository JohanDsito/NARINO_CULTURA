import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narino_cultura/core/network/api_client.dart';
import 'package:narino_cultura/features/auth/presentation/screens/login_screen.dart';
import 'package:narino_cultura/features/auth/presentation/screens/register_screen.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/catalog_screen.dart';
import 'package:narino_cultura/features/home/presentation/screens/home_screen.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';
import 'package:narino_cultura/features/notifications/presentation/providers/notifications_provider.dart';

class _FakeArtworkRepository extends ArtworkRepository {
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
    return (artworks: const <ArtworkModel>[], total: 0);
  }
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  testWidgets('LoginScreen renderiza con correo y contraseña',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });

  testWidgets('RegisterScreen renderiza con los tres chips de rol',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Artista'), findsOneWidget);
    expect(find.text('Comprador'), findsOneWidget);
    expect(find.text('Gestor Cultural'), findsOneWidget);
  });

  testWidgets(
      'CatalogScreen renderiza el AppBar con título "Catálogo de Obras"',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        const CatalogScreen(),
        overrides: [
          artworkRepositoryProvider.overrideWithValue(_FakeArtworkRepository()),
        ],
      ),
    );

    expect(find.text('Catálogo de Obras'), findsOneWidget);
  });

  testWidgets('HomeScreen renderiza el AppBar con el nombre "Nariño Cultura"',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        const HomeScreen(),
        overrides: [
          unreadNotificationsCountProvider.overrideWith((ref) async => 0),
          homeFeaturedArtworksProvider.overrideWith(
            (ref, limit) async => const <ArtworkModel>[],
          ),
          homeUpcomingEventsProvider.overrideWith(
            (ref, limit) async => const <EventModel>[],
          ),
          homeAiArtworkRecommendationsProvider.overrideWith(
            (ref, limit) async => const <ArtworkModel>[],
          ),
        ],
      ),
    );

    expect(find.text('Nariño Cultura'), findsOneWidget);
  });
}
