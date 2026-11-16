// Pruebas de accesibilidad con las pautas oficiales de Flutter:
// MO-ACC-01 (etiquetas y acciones) y MO-ACC-04 (48×48). El contraste
// (MO-ACC-03) se calcula en contrast_test.dart a partir de los colores del tema.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/theme/app_theme.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/catalog_screen/artwork_card.dart';
import 'package:narino_cultura/features/auth/presentation/screens/login_screen.dart';
import 'package:narino_cultura/features/home/presentation/screens/home_screen/home_header_actions.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:narino_cultura/shared/widgets/design/design.dart';

import '../support/test_helpers.dart';

final _obra = testArtwork(
  id: 'x',
  titulo: 'Cóndor Andino',
  artistaNombre: 'María Torres',
  precio: 320000,
);

Widget _app(Widget home, {bool dark = false}) => ProviderScope(
      overrides: [
        favoritesProvider.overrideWith((ref) => NoOpFavoritesNotifier()),
        unreadNotificationsCountProvider.overrideWith((ref) async => 3),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: home,
      ),
    );

Future<void> _meetsAll(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  setUpAll(ensureApiClientInitialized);

  for (final dark in [false, true]) {
    final modo = dark ? 'oscuro' : 'claro';

    testWidgets('Login cumple 48×48 y etiquetas ($modo)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const LoginScreen(), dark: dark));
      await tester.pump(const Duration(milliseconds: 500));
      await _meetsAll(tester);
      handle.dispose();
    });

    testWidgets('Encabezado de Inicio: botones de 48×48 ($modo)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(
        const Scaffold(appBar: NcGlassHeader(actions: homeHeaderActions)),
        dark: dark,
      ));
      await tester.pump();
      await _meetsAll(tester);
      handle.dispose();
    });
  }

  testWidgets('Tarjeta de obra: el corazón es un botón propio y activable',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(Scaffold(
      body: Center(
        child: SizedBox(
          width: 180,
          height: 280,
          child: CatalogArtworkCard(artwork: _obra),
        ),
      ),
    )));
    await tester.pump();
    await _meetsAll(tester);

    // El corazón ya no se funde con la tarjeta y TalkBack puede activarlo.
    expect(
      find.semantics.byLabel('Agregar a favoritos'),
      isSemantics(isButton: true, hasTapAction: true),
    );

    // La tarjeta se anuncia una vez (sin repetir título y artista) y abre la obra.
    expect(
      find.semantics.byLabel(RegExp(r'^Cóndor Andino, de María Torres')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('Pestañas, botón de vidrio y chips se pueden activar con lector',
      (tester) async {
    final handle = tester.ensureSemantics();
    var tabs = 0;
    var vuelve = 0;
    await tester.pumpWidget(_app(Scaffold(
      body: Center(
        child: GlassCircleButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Volver',
          onPressed: () => vuelve++,
        ),
      ),
      bottomNavigationBar: NcTabBar(
        currentIndex: 0,
        onTap: (_) => tabs++,
        items: const [
          NcTabItem(label: 'Inicio', icon: Icons.home_rounded),
          NcTabItem(label: 'Catálogo', icon: Icons.palette_outlined),
        ],
      ),
    )));
    await tester.pump();
    await _meetsAll(tester);

    // Antes estos nodos se anunciaban como botón pero sin acción de toque.
    tester.semantics.tap(find.semantics.byLabel('Volver'));
    tester.semantics.tap(find.semantics.byLabel(RegExp('Catálogo')));
    await tester.pump();
    expect(vuelve, 1);
    expect(tabs, 1);
    handle.dispose();
  });
}
