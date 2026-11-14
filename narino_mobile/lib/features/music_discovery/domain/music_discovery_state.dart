import '../../musicians/domain/musician_model.dart';

class MusicDiscoveryState {
  const MusicDiscoveryState({
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastQuery = '',
    this.hasSearched = false,
  });

  final List<MusicianModel> results;
  final bool isLoading;
  final String? errorMessage;
  final String lastQuery;
  final bool hasSearched;

  bool get hasError => errorMessage != null;

  MusicDiscoveryState copyWith({
    List<MusicianModel>? results,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? lastQuery,
    bool? hasSearched,
  }) {
    return MusicDiscoveryState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastQuery: lastQuery ?? this.lastQuery,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}
