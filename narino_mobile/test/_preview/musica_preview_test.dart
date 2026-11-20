// TEMPORAL / herramienta de diseño: capturas de Músicos y Descubrimiento.
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/music_discovery/presentation/screens/music_discovery_screen.dart';
import 'package:narino_cultura/features/musicians/data/musician_repository.dart';
import 'package:narino_cultura/features/musicians/domain/musician_model.dart';
import 'package:narino_cultura/features/musicians/presentation/providers/musician_provider.dart';
import 'package:narino_cultura/features/musicians/presentation/screens/musician_detail_screen.dart';
import 'package:narino_cultura/features/musicians/presentation/screens/musicians_screen.dart';

import 'preview_support.dart';

const _m1 = MusicianModel(
  slug: 'tierra-de-volcanes',
  name: 'Tierra de Volcanes',
  bio: 'Ensamble andino de Pasto que mezcla quena, charango y bajo eléctrico '
      'con letras sobre el Galeras y el Carnaval.',
  city: 'Pasto',
  genres: ['Andina', 'Fusión', 'Rock'],
  aggregationType: 'BANDA',
  isFollowing: false,
  followersCount: 248,
  averageRating: 4.6,
  reviewsCount: 12,
  isVerified: true,
);
const _m2 = MusicianModel(
  slug: 'valentina-guerrero',
  name: 'Valentina Guerrero',
  city: 'Ipiales',
  genres: ['Trova', 'Bolero'],
  aggregationType: 'SOLISTA',
  isFollowing: false,
  followersCount: 87,
  averageRating: 0,
  reviewsCount: 0,
  isVerified: false,
);

class _Repo extends MusicianRepository {
  @override
  Future<List<MusicianModel>> getMusicians(
          {String? search, String? genre, String? city, String? aggregationType, int page = 1}) async =>
      [_m1, _m2];
  @override
  Future<List<MusicGenreModel>> getGenres() async => const [
        MusicGenreModel(id: 1, name: 'Andina', slug: 'andina'),
        MusicGenreModel(id: 2, name: 'Cumbia', slug: 'cumbia'),
        MusicGenreModel(id: 3, name: 'Rock', slug: 'rock'),
        MusicGenreModel(id: 4, name: 'Trova', slug: 'trova'),
      ];
  @override
  Future<Set<String>> getFollowingSlugs() async => {'tierra-de-volcanes'};
  @override
  Future<MusicianModel> getMusicianDetail(String slug) async => _m1;
  @override
  Future<List<MusicalWorkModel>> getMusicianWorks(String slug) async => [
        MusicalWorkModel(id: 'w1', title: 'Galeras en llamas', createdAt: DateTime(2025),
            workType: 'VIDEO', year: 2025, durationSeconds: 245,
            youtubeUrl: 'https://youtube.com/x', spotifyTrackUrl: 'https://open.spotify.com/x'),
        MusicalWorkModel(id: 'w2', title: 'Negros y Blancos (en vivo)', createdAt: DateTime(2024),
            workType: 'LIVE', year: 2024, youtubeUrl: 'https://youtube.com/y'),
      ];
  @override
  Future<List<MusicianReviewModel>> getMusicianReviews(String slug) async => const [];
  @override
  Future<MusicianModel?> getMyProfile() async => null;
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    final ov = [
      musicianRepositoryProvider.overrideWithValue(_Repo()),
      currentUserRoleProvider.overrideWith((ref) async => 'comprador'),
    ];
    testWidgets('musicos', skip: previewSkip, (t) async {
      await capture(t, name: 'musicos', dark: dark, overrides: ov, height: 1100,
          home: const MusiciansScreen());
    });
    testWidgets('musico_detalle', skip: previewSkip, (t) async {
      await capture(t, name: 'musico_detalle', dark: dark, overrides: ov, height: 1300,
          home: const MusicianDetailScreen(slug: 'tierra-de-volcanes'));
    });
    testWidgets('descubrir', skip: previewSkip, (t) async {
      await capture(t, name: 'descubrir', dark: dark, overrides: ov, height: 900,
          home: const MusicDiscoveryScreen());
    });
  }
}
