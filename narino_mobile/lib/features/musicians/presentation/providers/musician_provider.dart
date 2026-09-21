import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/musician_repository.dart';
import '../../domain/musician_model.dart';

final musicianRepositoryProvider = Provider<MusicianRepository>(
  (ref) => MusicianRepository(),
);

// ─── Géneros ──────────────────────────────────────────────────────────────────

final musicGenresProvider =
    FutureProvider.autoDispose<List<MusicGenreModel>>((ref) async {
  return ref.read(musicianRepositoryProvider).getGenres();
});

// ─── Lista de músicos ─────────────────────────────────────────────────────────

class MusicianListState {
  const MusicianListState({
    this.musicians = const [],
    this.isLoading = false,
    this.errorMessage,
    this.search = '',
    this.genreFilter,
    this.cityFilter,
  });

  final List<MusicianModel> musicians;
  final bool isLoading;
  final String? errorMessage;
  final String search;
  final String? genreFilter;
  final String? cityFilter;

  bool get hasError => errorMessage != null;

  MusicianListState copyWith({
    List<MusicianModel>? musicians,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? search,
    String? genreFilter,
    bool clearGenreFilter = false,
    String? cityFilter,
    bool clearCityFilter = false,
  }) {
    return MusicianListState(
      musicians: musicians ?? this.musicians,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      search: search ?? this.search,
      genreFilter: clearGenreFilter ? null : genreFilter ?? this.genreFilter,
      cityFilter: clearCityFilter ? null : cityFilter ?? this.cityFilter,
    );
  }
}

final musicianListProvider =
    StateNotifierProvider<MusicianListNotifier, MusicianListState>(
  (ref) => MusicianListNotifier(ref.read(musicianRepositoryProvider)),
);

class MusicianListNotifier extends StateNotifier<MusicianListState> {
  MusicianListNotifier(this._repo) : super(const MusicianListState()) {
    load();
  }

  final MusicianRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getMusicians(
        search: state.search.isEmpty ? null : state.search,
        genre: state.genreFilter,
        city: state.cityFilter,
      );
      state = state.copyWith(isLoading: false, musicians: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value);
    load();
  }

  void setGenre(String? genre) {
    state = state.copyWith(
      genreFilter: genre,
      clearGenreFilter: genre == null,
    );
    load();
  }

  void setCity(String? city) {
    state = state.copyWith(
      cityFilter: city,
      clearCityFilter: city == null,
    );
    load();
  }

  void clearFilters() {
    state = const MusicianListState();
    load();
  }

  Future<void> toggleFollow(String slug) async {
    final idx = state.musicians.indexWhere((m) => m.slug == slug);
    if (idx == -1) return;
    final before = state.musicians[idx];
    final optimistic = before.copyWith(
      isFollowing: !before.isFollowing,
      followersCount: before.isFollowing
          ? (before.followersCount - 1).clamp(0, 1 << 30)
          : before.followersCount + 1,
    );
    final updated = [...state.musicians];
    updated[idx] = optimistic;
    state = state.copyWith(musicians: updated);

    try {
      await _repo.toggleFollow(slug);
    } catch (_) {
      final revert = [...state.musicians];
      final currentIdx = revert.indexWhere((m) => m.slug == slug);
      if (currentIdx != -1) {
        revert[currentIdx] = before;
        state = state.copyWith(musicians: revert);
      }
    }
  }
}

// ─── Detalle de músico ────────────────────────────────────────────────────────

final musicianDetailProvider = FutureProvider.autoDispose
    .family<MusicianModel, String>((ref, slug) async {
  return ref.read(musicianRepositoryProvider).getMusicianDetail(slug);
});

final musicianWorksProvider = FutureProvider.autoDispose
    .family<List<MusicalWorkModel>, String>((ref, slug) async {
  return ref.read(musicianRepositoryProvider).getMusicianWorks(slug);
});

final musicianReviewsProvider = FutureProvider.autoDispose
    .family<List<MusicianReviewModel>, String>((ref, slug) async {
  return ref.read(musicianRepositoryProvider).getMusicianReviews(slug);
});

// ─── Perfil propio del músico (slug) ─────────────────────────────────────────

/// Devuelve el slug del perfil de músico del usuario autenticado, o null si
/// todavía no ha creado su perfil musical.
final myMusicianSlugProvider = FutureProvider.autoDispose<String?>((ref) async {
  final profile = await ref.read(musicianRepositoryProvider).getMyProfile();
  return profile?.slug;
});
