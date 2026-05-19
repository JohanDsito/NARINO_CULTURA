import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narino_cultura/core/network/api_client.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/auth/presentation/screens/login_screen.dart';
import 'package:narino_cultura/features/auth/presentation/screens/register_screen.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/catalog_screen.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';
import 'package:narino_cultura/features/home/presentation/screens/home_screen.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_repository.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:narino_cultura/features/profile/data/profile_repository.dart';
import 'package:narino_cultura/features/profile/presentation/providers/profile_provider.dart';
import 'package:narino_cultura/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:narino_cultura/shared/widgets/artwork_card.dart';

// ─── Fake repositories ────────────────────────────────────────────────────────

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

// ─── Fake notifiers (no-op: evitan llamadas de red en tests) ─────────────────

class _NoOpProfileNotifier extends ProfileNotifier {
  _NoOpProfileNotifier() : super(ProfileRepository());

  @override
  Future<void> loadMyProfile() async {}

  @override
  Future<void> loadPortfolio(String profileId) async {}
}

class _NoOpFavoritesNotifier extends FavoritesNotifier {
  _NoOpFavoritesNotifier() : super(MarketplaceRepository());

  @override
  Future<void> loadFavorites() async {}
}

// ─── Helper ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

ArtworkModel _artwork({
  String id = 'test-id',
  String titulo = 'Obra de prueba',
  String artistaNombre = 'Artista Test',
  String estado = 'disponible',
  double? precio,
  List<String> imagenes = const [],
}) {
  return ArtworkModel(
    id: id,
    titulo: titulo,
    descripcion: '',
    categoria: 'Pintura',
    estado: estado,
    imagenes: imagenes,
    artistaId: 'artist-1',
    artistaNombre: artistaNombre,
    precio: precio,
    cantidadFavoritos: 0,
    esFavorito: false,
    creadoEn: DateTime(2025, 1, 1),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    ApiClient.instance.init();
  });

  // MO-WT-01
  testWidgets('LoginScreen renderiza con correo y contraseña',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });

  // MO-WT-02
  testWidgets('RegisterScreen renderiza con las tres opciones de rol',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));

    expect(find.text('Artista'), findsOneWidget);
    expect(find.text('Comprador'), findsOneWidget);
    expect(find.text('Gestor Cultural'), findsOneWidget);
  });

  // MO-WT-03
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

  // MO-WT-04
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

  // MO-WT-05
  testWidgets('ArtworkCard renderiza el título y el nombre del artista',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(Scaffold(
        body: SizedBox(
          width: 180,
          height: 260,
          child: ArtworkCard(
            artwork: _artwork(titulo: 'Barniz de Pasto', artistaNombre: 'Ana Díaz'),
          ),
        ),
      )),
    );

    expect(find.text('Barniz de Pasto'), findsOneWidget);
    expect(find.text('Ana Díaz'), findsOneWidget);
  });

  // MO-WT-06
  testWidgets('ArtworkCard sin imágenes muestra el ícono de paleta',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(Scaffold(
        body: SizedBox(
          width: 180,
          height: 260,
          child: ArtworkCard(artwork: _artwork(imagenes: const [])),
        ),
      )),
    );

    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
  });

  // MO-WT-07
  testWidgets('ArtworkCard formatea el precio con separadores de miles en COP',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(Scaffold(
        body: SizedBox(
          width: 180,
          height: 260,
          child: ArtworkCard(artwork: _artwork(precio: 1500000)),
        ),
      )),
    );

    expect(find.text(r'$1.500.000 COP'), findsOneWidget);
  });

  // MO-WT-08
  testWidgets('ArtworkCard muestra el badge "Vendida" cuando estado es vendida',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(Scaffold(
        body: SizedBox(
          width: 180,
          height: 260,
          child: ArtworkCard(artwork: _artwork(estado: 'vendida')),
        ),
      )),
    );

    expect(find.text('Vendida'), findsOneWidget);
  });

  // MO-WT-09
  testWidgets('MyProfileScreen muestra las opciones principales del menú',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        const MyProfileScreen(),
        overrides: [
          myProfileProvider.overrideWith((_) => _NoOpProfileNotifier()),
          favoritesProvider.overrideWith((_) => _NoOpFavoritesNotifier()),
          currentUserRoleProvider.overrideWith((ref) async => null),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis obras'), findsOneWidget);
    expect(find.text('Mi portafolio'), findsOneWidget);
    expect(find.text('Artistas que sigo'), findsOneWidget);
  });

  // MO-WT-10
  testWidgets('MyProfileScreen muestra las opciones de favoritos y compras',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        const MyProfileScreen(),
        overrides: [
          myProfileProvider.overrideWith((_) => _NoOpProfileNotifier()),
          favoritesProvider.overrideWith((_) => _NoOpFavoritesNotifier()),
          currentUserRoleProvider.overrideWith((ref) async => null),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis favoritos'), findsOneWidget);
    expect(find.text('Mis compras'), findsOneWidget);
  });
}
