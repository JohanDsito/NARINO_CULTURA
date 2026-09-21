import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/profile/presentation/providers/profile_provider.dart';
import 'package:narino_cultura/features/profile/presentation/screens/my_profile_screen.dart';

import '../../../../support/test_helpers.dart';

void main() {
  setUpAll(ensureApiClientInitialized);

  // MO-WT-09
  testWidgets(
      'MyProfileScreen muestra las opciones principales del menú (rol artista)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const MyProfileScreen(),
        overrides: [
          myProfileProvider.overrideWith((_) => NoOpProfileNotifier()),
          favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
          currentUserRoleProvider.overrideWith((ref) async => 'artista'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // "Mis obras" y "Mi portafolio" solo se muestran para artista/admin.
    expect(find.text('Mis obras'), findsOneWidget);
    expect(find.text('Mi portafolio'), findsOneWidget);
    expect(find.text('Artistas que sigo'), findsOneWidget);
  });

  // MO-WT-10
  testWidgets('MyProfileScreen muestra las opciones de favoritos y compras',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        const MyProfileScreen(),
        overrides: [
          myProfileProvider.overrideWith((_) => NoOpProfileNotifier()),
          favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
          currentUserRoleProvider.overrideWith((ref) async => null),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis favoritos'), findsOneWidget);
    expect(find.text('Mis compras'), findsOneWidget);
  });
}
