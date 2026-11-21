// TEMPORAL / evidencia de los casos de prueba MO-*: capturas de los estados que
// se arreglaron (sin conexión, sesión expirada, errores, fin del catálogo…).
// Se saltan si no se pasa --dart-define=OUT=<carpeta> (ver preview_support.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/api_error.dart';
import 'package:narino_cultura/core/network/session_expiry.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/core/router/main_shell.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/catalog_screen.dart';
import 'package:narino_cultura/features/auth/data/auth_repository.dart';
import 'package:narino_cultura/features/auth/domain/auth_state.dart';
import 'package:narino_cultura/features/auth/presentation/providers/auth_provider.dart';
import 'package:narino_cultura/features/auth/presentation/screens/login_screen.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';
import 'package:narino_cultura/features/home/presentation/screens/home_screen.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_repository.dart';
import 'package:narino_cultura/features/marketplace/domain/favorite_model.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/cart_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:narino_cultura/features/notifications/presentation/providers/notifications_provider.dart';

import '../support/test_helpers.dart';
import 'preview_support.dart';

/// Login con un error ya mostrado (el que devolvería el repositorio).
class _AuthConError extends AuthNotifier {
  _AuthConError(String mensaje) : super(AuthRepository()) {
    state = AuthState(status: AuthStatus.unauthenticated, errorMessage: mensaje);
  }
}

class _FavsSinRed extends MarketplaceRepository {
  @override
  Future<List<FavoriteModel>> getFavorites() async => throw ApiError.sinConexion;
}

/// 26 obras en páginas de 20 (para llegar al final del catálogo).
class _CatalogoPaginado extends ArtworkRepository {
  static const _titulos = [
    'Cóndor Andino', 'Volcán Galeras', 'Carnaval Eterno', 'Tejido Guaneña',
    'Barniz de Pasto', 'Laguna de la Cocha', 'Santuario de Las Lajas', 'Cuy de fiesta',
  ];
  static const _artistas = ['María Torres', 'Luis Zambrano', 'Ana Benavides', 'Carlos Díaz'];

  @override
  Future<({List<ArtworkModel> artworks, int total})> getCatalog({
    String? search, String? categoria, String? tecnica, double? precioMin,
    double? precioMax, String ordenarPor = 'fecha', int page = 1,
  }) async {
    final desde = (page - 1) * 20;
    final hasta = (desde + 20).clamp(0, 26);
    return (
      artworks: [
        for (var i = desde; i < hasta; i++)
          testArtwork(
            id: '$i',
            titulo: _titulos[i % _titulos.length],
            artistaNombre: _artistas[i % _artistas.length],
            precio: 90000.0 + i * 15000,
          ),
      ],
      total: 26,
    );
  }

  @override
  Future<List<CategoryModel>> getCategories() async => const [
        CategoryModel(id: 1, name: 'Pintura', slug: 'pintura'),
        CategoryModel(id: 2, name: 'Escultura', slug: 'escultura'),
      ];
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [false, true]) {
    final m = dark ? 'oscuro' : 'claro';

    // MO-DISP-01 (#125): Inicio sin conexión.
    testWidgets('ev_inicio_sin_conexion $m', skip: previewSkip, (t) async {
      await capture(t,
          name: 'ev_inicio_sin_conexion',
          dark: dark,
          overrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
            homeFeaturedArtworksProvider
                .overrideWith((ref, l) => Future.error(ApiError.sinConexion)),
            homeUpcomingEventsProvider.overrideWith(
                (ref, l) => Future<List<EventModel>>.error(ApiError.sinConexion)),
            homeAiArtworkRecommendationsProvider
                .overrideWith((ref, l) async => const <ArtworkModel>[]),
            currentUserRoleProvider.overrideWith((ref) async => 'COMPRADOR'),
          ],
          home: const MainShell(location: '/home', child: HomeScreen()));
    });

    // MO-USA-02 (#133): credenciales incorrectas con el siguiente paso.
    testWidgets('ev_login_credenciales $m', skip: previewSkip, (t) async {
      await capture(t,
          name: 'ev_login_credenciales',
          dark: dark,
          overrides: [
            authProvider.overrideWith((ref) => _AuthConError(
                AuthRepository.friendlyLoginMessage('Credenciales inválidas.'))),
          ],
          home: const LoginScreen());
    });

    // MO-DISP-03 (#127): tiempo agotado explícito.
    testWidgets('ev_login_tiempo_agotado $m', skip: previewSkip, (t) async {
      await capture(t,
          name: 'ev_login_tiempo_agotado',
          dark: dark,
          overrides: [
            authProvider
                .overrideWith((ref) => _AuthConError(ApiError.tiempoAgotado)),
          ],
          home: const LoginScreen());
    });

    // MO-SEG-04 (#140): llegada al login por sesión expirada.
    testWidgets('ev_login_sesion_expirada $m', skip: previewSkip, (t) async {
      SessionExpiry.expire();
      await capture(t,
          name: 'ev_login_sesion_expirada', dark: dark, home: const LoginScreen());
    });

    // MO-ACC-03 (#123): errores de validación con el color de contraste AA.
    testWidgets('ev_login_validacion $m', skip: previewSkip, (t) async {
      await capture(t,
          name: 'ev_login_validacion',
          dark: dark,
          home: const LoginScreen(),
          interact: (t) async {
            await t.tap(find.text('Iniciar sesión').last);
          });
    });

    // #76: Favoritos sin conexión (antes decía "Aún no guardas favoritos").
    testWidgets('ev_favoritos_error $m', skip: previewSkip, (t) async {
      await capture(t,
          name: 'ev_favoritos_error',
          dark: dark,
          overrides: [
            marketplaceRepositoryProvider.overrideWithValue(_FavsSinRed()),
          ],
          home: const FavoritesScreen());
    });

    // MO-LOAD-01 (#130): el scroll trae todas las páginas hasta el final.
    testWidgets('ev_catalogo_final $m', skip: previewSkip, (t) async {
      await capture(t,
          name: 'ev_catalogo_final',
          dark: dark,
          overrides: [
            artworkRepositoryProvider.overrideWithValue(_CatalogoPaginado()),
            favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
            currentUserRoleProvider.overrideWith((ref) async => 'COMPRADOR'),
          ],
          home: const MainShell(location: '/catalog', child: CatalogScreen()),
          interact: (t) async {
            for (var i = 0; i < 12; i++) {
              await t.drag(find.byType(CustomScrollView), const Offset(0, -900));
              await t.pump(const Duration(milliseconds: 200));
            }
          });
    });
  }
}
