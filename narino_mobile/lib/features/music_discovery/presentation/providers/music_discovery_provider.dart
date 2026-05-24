import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/music_discovery_repository.dart';
import '../../../musicians/domain/musician_model.dart';

final musicDiscoveryRepositoryProvider =
    Provider<MusicDiscoveryRepository>((ref) => MusicDiscoveryRepository());

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

final musicDiscoveryProvider =
    StateNotifierProvider.autoDispose<MusicDiscoveryNotifier, MusicDiscoveryState>(
  (ref) => MusicDiscoveryNotifier(ref.read(musicDiscoveryRepositoryProvider)),
);

class MusicDiscoveryNotifier extends StateNotifier<MusicDiscoveryState> {
  MusicDiscoveryNotifier(this._repo) : super(const MusicDiscoveryState());

  final MusicDiscoveryRepository _repo;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastQuery: query.trim(),
    );
    try {
      final results = await _repo.getRecommendations(query.trim());
      state = state.copyWith(
        isLoading: false,
        results: results,
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        hasSearched: true,
      );
    }
  }

  void clear() {
    state = const MusicDiscoveryState();
  }
}
