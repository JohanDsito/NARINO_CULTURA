import 'package:flutter_test/flutter_test.dart';
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
}
