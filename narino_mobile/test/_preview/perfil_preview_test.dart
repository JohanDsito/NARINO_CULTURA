// TEMPORAL / herramienta de diseño: capturas del módulo de perfil.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_repository.dart';
import 'package:narino_cultura/features/marketplace/domain/order_model.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/cart_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/profile/data/profile_repository.dart';
import 'package:narino_cultura/features/profile/domain/profile_model.dart';
import 'package:narino_cultura/features/profile/domain/profile_state.dart';
import 'package:narino_cultura/features/profile/presentation/providers/profile_provider.dart';
import 'package:narino_cultura/features/profile/presentation/screens/artist_public_profile_screen.dart';
import 'package:narino_cultura/features/profile/presentation/screens/artist_stats_screen.dart';
import 'package:narino_cultura/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:narino_cultura/features/profile/presentation/screens/following_screen.dart';
import 'package:narino_cultura/features/profile/presentation/screens/my_profile_screen.dart';

import '../support/test_helpers.dart';
import 'preview_support.dart';

const _yo = ProfileModel(
  id: 'valery-ortiz',
  userId: '7',
  nombreArtistico: 'Valery Ortiz',
  disciplina: 'Pintura',
  biografia: 'Pinto el Carnaval de Negros y Blancos desde los talleres de Pasto.',
  seguidores: 132,
  siguiendo: 18,
  esSeguido: false,
  esVerificado: true,
  redesSociales: {'instagram': 'https://instagram.com/x'},
  totalObras: 9,
  obrasDisponibles: 5,
  ciudad: 'Pasto',
);

const _artista = ProfileModel(
  id: 'maria-torres',
  userId: '3',
  nombreArtistico: 'María Torres',
  disciplina: 'Pintura',
  biografia: 'Óleos sobre la fauna andina y los volcanes de Nariño. '
      'Trabajo con pigmentos naturales del Putumayo.',
  seguidores: 248,
  siguiendo: 12,
  esSeguido: false,
  esVerificado: true,
  redesSociales: {
    'instagram': 'https://instagram.com/x',
    'website': 'https://x.co',
  },
  totalObras: 4,
  obrasDisponibles: 2,
  ciudad: 'Ipiales',
);

class _Repo extends ProfileRepository {
  @override
  Future<ProfileModel> getProfileById(String id) async => _artista;
  @override
  Future<List<ProfileModel>> getMyFollowing() async => [
        _artista,
        const ProfileModel(
          id: 'tierra-de-volcanes', userId: '9', nombreArtistico: 'Tierra de Volcanes',
          disciplina: '', seguidores: 0, siguiendo: 0, esSeguido: true,
          esVerificado: false, redesSociales: {}, totalObras: 0,
          obrasDisponibles: 0, esMusico: true),
        const ProfileModel(
          id: 'luis-zambrano', userId: '5', nombreArtistico: 'Luis Zambrano',
          disciplina: 'Artesano', seguidores: 0, siguiendo: 0, esSeguido: true,
          esVerificado: false, redesSociales: {}, totalObras: 0,
          obrasDisponibles: 0, ciudad: 'Sandoná'),
      ];
}

class _Notifier extends NoOpProfileNotifier {
  _Notifier() {
    state = const ProfileState(status: ProfileStatus.success, profile: _yo);
  }
}

class _MRepo extends MarketplaceRepository {
  @override
  Future<List<OrderModel>> getSalesHistory() async => [
        OrderModel(id: 'a1', estado: 'completado', total: 320000, montoVendedor: 320000,
            creadoEn: DateTime.now(), items: const []),
        OrderModel(id: 'a2', estado: 'completado', total: 180000, montoVendedor: 180000,
            creadoEn: DateTime(2026, 9, 3), items: const []),
      ];
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    List<Override> ov() => [
      profileRepositoryProvider.overrideWithValue(_Repo()),
      myProfileProvider.overrideWith((_) => _Notifier()),
      favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
      currentUserRoleProvider.overrideWith((ref) async => 'artista'),
      marketplaceRepositoryProvider.overrideWithValue(_MRepo()),
      artistArtworksProvider.overrideWith((ref, slug) async => [
            testArtwork(id: '1', titulo: 'Cóndor Andino', artistaNombre: 'María Torres', precio: 320000, viewsCount: 1284),
            testArtwork(id: '2', titulo: 'Volcán Galeras', artistaNombre: 'María Torres', precio: 180000, estado: 'vendida', viewsCount: 932),
            testArtwork(id: '3', titulo: 'Colibrí', artistaNombre: 'María Torres', precio: 95000, viewsCount: 210),
            testArtwork(id: '4', titulo: 'Guaneña en barniz de Pasto', artistaNombre: 'María Torres', precio: 95000, estado: 'en_subasta', viewsCount: 64),
          ]),
    ];
    testWidgets('mi_perfil', skip: previewSkip, (t) async {
      await capture(t, name: 'mi_perfil', dark: dark, overrides: ov(), height: 1700,
          home: const MainShell(location: '/profile', child: MyProfileScreen()));
    });
    testWidgets('editar_perfil', skip: previewSkip, (t) async {
      await capture(t, name: 'editar_perfil', dark: dark, overrides: ov(), height: 1650,
          home: const EditProfileScreen());
    });
    testWidgets('siguiendo', skip: previewSkip, (t) async {
      await capture(t, name: 'siguiendo', dark: dark, overrides: ov(), height: 700,
          home: const FollowingScreen());
    });
    testWidgets('estadisticas', skip: previewSkip, (t) async {
      await capture(t, name: 'estadisticas', dark: dark, overrides: ov(), height: 1150,
          home: const ArtistStatsScreen());
    });
    testWidgets('perfil_publico', skip: previewSkip, (t) async {
      await capture(t, name: 'perfil_publico', dark: dark, overrides: ov(), height: 1350,
          home: const ArtistPublicProfileScreen(artistId: 'maria-torres'));
    });
  }
}
