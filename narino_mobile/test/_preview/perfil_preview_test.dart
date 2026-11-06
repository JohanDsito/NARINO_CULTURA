// TEMPORAL / herramienta de diseño: capturas del módulo de perfil.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/profile/data/profile_repository.dart';
import 'package:narino_cultura/features/profile/domain/profile_model.dart';
import 'package:narino_cultura/features/profile/domain/profile_state.dart';
import 'package:narino_cultura/features/profile/presentation/providers/profile_provider.dart';
import 'package:narino_cultura/features/profile/presentation/screens/artist_public_profile_screen.dart';
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
  Future<List<ProfileModel>> getMyFollowing() async => [_artista];
}

class _Notifier extends NoOpProfileNotifier {
  _Notifier() {
    state = const ProfileState(status: ProfileStatus.success, profile: _yo);
  }
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    List<Override> ov() => [
      profileRepositoryProvider.overrideWithValue(_Repo()),
      myProfileProvider.overrideWith((_) => _Notifier()),
      favoritesProvider.overrideWith((_) => NoOpFavoritesNotifier()),
      currentUserRoleProvider.overrideWith((ref) async => 'artista'),
      artistArtworksProvider.overrideWith((ref, slug) async => [
            testArtwork(id: '1', titulo: 'Cóndor Andino', artistaNombre: 'María Torres', precio: 320000),
            testArtwork(id: '2', titulo: 'Volcán Galeras', artistaNombre: 'María Torres', precio: 180000, estado: 'vendida'),
            testArtwork(id: '3', titulo: 'Colibrí', artistaNombre: 'María Torres', precio: 95000),
          ]),
    ];
    testWidgets('mi_perfil', skip: previewSkip, (t) async {
      await capture(t, name: 'mi_perfil', dark: dark, overrides: ov(), height: 1700,
          home: const MainShell(location: '/profile', child: MyProfileScreen()));
    });
    testWidgets('perfil_publico', skip: previewSkip, (t) async {
      await capture(t, name: 'perfil_publico', dark: dark, overrides: ov(), height: 1350,
          home: const ArtistPublicProfileScreen(artistId: 'maria-torres'));
    });
  }
}
