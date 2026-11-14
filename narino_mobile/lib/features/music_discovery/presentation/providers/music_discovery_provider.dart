import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/music_discovery_repository.dart';
import '../../domain/music_discovery_state.dart';

export '../../domain/music_discovery_state.dart';

final musicDiscoveryRepositoryProvider =
    Provider<MusicDiscoveryRepository>((ref) => MusicDiscoveryRepository());

final musicDiscoveryProvider = StateNotifierProvider.autoDispose<
    MusicDiscoveryNotifier, MusicDiscoveryState>(
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
