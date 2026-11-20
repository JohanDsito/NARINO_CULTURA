import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/api_error.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';
import 'package:narino_cultura/features/home/presentation/screens/home_screen.dart';
import 'package:narino_cultura/features/notifications/presentation/providers/notifications_provider.dart';

import '../../../../support/test_helpers.dart';

void main() {
  setUpAll(ensureApiClientInitialized);

  // MO-WT-04
  testWidgets('HomeScreen renderiza el AppBar con el nombre "Nariño Cultura"',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
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

  List<Override> overrides({
    required Future<List<ArtworkModel>> Function() featured,
    required Future<List<EventModel>> Function() events,
  }) =>
      [
        unreadNotificationsCountProvider.overrideWith((ref) async => 0),
        homeFeaturedArtworksProvider.overrideWith((ref, limit) => featured()),
        homeUpcomingEventsProvider.overrideWith((ref, limit) => events()),
        homeAiArtworkRecommendationsProvider.overrideWith(
          (ref, limit) async => const <ArtworkModel>[],
        ),
      ];

  // MO-DISP-01: sin red, Inicio dice por qué no hay contenido y deja reintentar.
  testWidgets('sin conexión muestra el aviso con Reintentar', (tester) async {
    await tester.pumpWidget(wrap(
      const HomeScreen(),
      overrides: overrides(
        featured: () => Future.error(ApiError.sinConexion),
        events: () => Future.error(ApiError.sinConexion),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(ApiError.sinConexion), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('si solo falla una sección no muestra el aviso general',
      (tester) async {
    await tester.pumpWidget(wrap(
      const HomeScreen(),
      overrides: overrides(
        featured: () async => const <ArtworkModel>[],
        events: () => Future.error(ApiError.sinConexion),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsNothing);
  });
}
