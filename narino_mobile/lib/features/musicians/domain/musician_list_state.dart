import 'musician_model.dart';

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
