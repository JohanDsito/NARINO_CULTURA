import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/musician_repository.dart';
import 'musician_provider.dart';

final seguidosProvider = StateNotifierProvider<SeguidosNotifier, SeguidosState>(
  (ref) => SeguidosNotifier(ref.read(musicianRepositoryProvider)),
);

class SeguidosNotifier extends StateNotifier<SeguidosState> {
  SeguidosNotifier(this._repo) : super(const SeguidosState()) {
    cargar();
  }

  final MusicianRepository _repo;

  Future<void> cargar() async {
    try {
      final slugs = await _repo.getFollowingSlugs();
      state = SeguidosState(inicial: slugs, actual: slugs);
    } catch (_) {
      // Sin sesión o sin red: nadie seguido; el botón sigue funcionando.
    }
  }

  /// Alterna seguir/dejar de seguir (optimista; revierte si falla).
  Future<bool> alternar(String slug) async {
    final antes = state;
    final siguiendo = state.actual.contains(slug);
    state = SeguidosState(
      inicial: state.inicial,
      actual: siguiendo
          ? ({...state.actual}..remove(slug))
          : {...state.actual, slug},
    );
    try {
      await _repo.toggleFollow(slug);
      return true;
    } catch (_) {
      state = antes;
      return false;
    }
  }
}
