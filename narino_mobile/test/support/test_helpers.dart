// Helpers compartidos por los widget tests: wrapper de ProviderScope+MaterialApp,
// fábrica de ArtworkModel de prueba, y fakes/no-ops para evitar llamadas de red
// reales durante los tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:narino_cultura/core/network/api_client.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_repository.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/profile/data/profile_repository.dart';
import 'package:narino_cultura/features/profile/presentation/providers/profile_provider.dart';

/// Inicializa el Dio compartido de la app. Los widgets que lean providers
/// dependientes de `ApiClient.instance` (aunque sea indirectamente) necesitan
/// esto en un `setUpAll` antes de montarse en un test.
void ensureApiClientInitialized() => ApiClient.instance.init();

// ─── Fake repositories ────────────────────────────────────────────────────────

class FakeArtworkRepository extends ArtworkRepository {
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

class NoOpProfileNotifier extends ProfileNotifier {
  NoOpProfileNotifier() : super(ProfileRepository());

  @override
  Future<void> loadMyProfile() async {}

  @override
  Future<void> loadPortfolio(String profileId) async {}
}

class NoOpFavoritesNotifier extends FavoritesNotifier {
  NoOpFavoritesNotifier() : super(MarketplaceRepository());

  @override
  Future<void> loadFavorites() async {}
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

Widget wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

ArtworkModel testArtwork({
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
    viewsCount: 0,
    esFavorito: false,
    creadoEn: DateTime(2025, 1, 1),
  );
}
