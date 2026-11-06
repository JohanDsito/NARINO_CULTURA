// TEMPORAL / herramienta de diseño: capturas del catálogo y perfil artístico.
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/artwork_detail_screen.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/catalog_screen.dart';
import 'package:narino_cultura/features/artworks/presentation/screens/publish_artwork_screen.dart';
import 'package:narino_cultura/features/auth/presentation/screens/artistic_profile_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';

import 'package:narino_cultura/features/profile/data/profile_repository.dart';
import 'package:narino_cultura/features/profile/domain/profile_model.dart';

import '../support/test_helpers.dart';
import 'preview_support.dart';

class _Repo extends ArtworkRepository {
  @override
  Future<({List<ArtworkModel> artworks, int total})> getCatalog({
    String? search, String? categoria, String? tecnica, double? precioMin,
    double? precioMax, String ordenarPor = 'fecha', int page = 1,
  }) async {
    final list = [
      testArtwork(id: '1', titulo: 'Cóndor Andino', artistaNombre: 'María Torres', precio: 320000),
      testArtwork(id: '2', titulo: 'Volcán Galeras al amanecer', artistaNombre: 'Luis Zambrano', precio: 180000, estado: 'en_subasta'),
      testArtwork(id: '3', titulo: 'Carnaval Eterno', artistaNombre: 'Ana Benavides', precio: 540000, estado: 'vendida'),
      testArtwork(id: '4', titulo: 'Tejido Guaneña', artistaNombre: 'Carlos Díaz', precio: 95000),
    ];
    return (artworks: list, total: 24);
  }

  @override
  Future<List<CategoryModel>> getCategories() async => const [
        CategoryModel(id: 1, name: 'Pintura', slug: 'pintura'),
        CategoryModel(id: 2, name: 'Escultura', slug: 'escultura'),
        CategoryModel(id: 3, name: 'Fotografia', slug: 'fotografia'),
        CategoryModel(id: 4, name: 'Artesania', slug: 'artesania'),
      ];
}

class _NoProfile extends ProfileRepository {
  @override
  Future<ProfileModel?> getMyProfile() async => null;
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    final overrides = [
      artworkRepositoryProvider.overrideWithValue(_Repo()),
      favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
      currentUserRoleProvider.overrideWith((ref) async => 'artista'),
    ];
    testWidgets('catalogo', skip: previewSkip, (t) async {
      await capture(t,
          name: 'catalogo',
          dark: dark,
          overrides: overrides,
          home: const MainShell(location: '/catalog', child: CatalogScreen()));
    });
    testWidgets('filtros', skip: previewSkip, (t) async {
      await capture(t,
          name: 'filtros',
          dark: dark,
          overrides: overrides,
          home: const CatalogScreen(), interact: (t) async {
        await t.tap(find.text('Filtros'));
      });
    });
    testWidgets('perfil_artistico', skip: previewSkip, (t) async {
      await capture(t,
          name: 'perfil_artistico',
          dark: dark,
          height: 1300,
          home: ArtisticProfileScreen(profileRepo: _NoProfile()), interact: (t) async {
        if (find.text('Pintura').evaluate().isNotEmpty) await t.tap(find.text('Pintura'));
      });
    });
    testWidgets('publicar', skip: previewSkip, (t) async {
      await capture(t,
          name: 'publicar',
          dark: dark,
          height: 1750,
          overrides: overrides,
          home: const PublishArtworkScreen(), interact: (t) async {
        await t.tap(find.text('Escultura'));
      });
    });
    testWidgets('detalle_obra', skip: previewSkip, (t) async {
      final obra = ArtworkModel(
        id: '9',
        titulo: 'Carnaval de Negros y Blancos',
        descripcion: 'Óleo sobre lienzo que retrata el desfile magno del 6 de '
            'enero en Pasto: carrozas, talco y la alegría de toda una ciudad '
            'que se pinta para celebrar la diversidad. Obra ganadora de la '
            'muestra regional 2025.',
        categoria: 'Pintura',
        tecnica: 'Óleo',
        dimensiones: '80 × 120 cm',
        anio: 2025,
        precio: 1250000,
        estado: 'disponible',
        imagenes: const [],
        artistaId: 'a1',
        artistaSlug: 'maria-torres',
        artistaNombre: 'María Torres',
        viewsCount: 128,
        esFavorito: false,
        creadoEn: DateTime(2025, 1, 6),
      );
      await capture(t,
          name: 'detalle_obra',
          dark: dark,
          height: 1500,
          overrides: [
            favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
            currentUserRoleProvider.overrideWith((ref) async => 'comprador'),
          ],
          home: ArtworkDetailScreen(artworkId: '9', initialArtwork: obra));
    });
  }
}
