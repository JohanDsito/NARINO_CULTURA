import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_repository.dart';
import '../../domain/profile_model.dart';
import '../../domain/profile_state.dart';
import '../../domain/portfolio_item_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref.read(profileRepositoryProvider)),
);

final myProfileProvider = profileProvider;

final publicProfileProvider = FutureProvider.family<ProfileModel, int>(
  (ref, id) => ref.read(profileRepositoryProvider).getProfileById(id),
);

final artistProfileProvider = publicProfileProvider;

final myFollowingProvider = FutureProvider<List<ProfileModel>>((ref) async {
  return ref.read(profileRepositoryProvider).getMyFollowing();
});

final followingProvider = myFollowingProvider;

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repo) : super(const ProfileState());

  final ProfileRepository _repo;

  Future<void> loadMyProfile() async {
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    try {
      final profile = await _repo.getMyProfile();
      state = state.copyWith(status: ProfileStatus.success, profile: profile);
    } catch (e) {
      state = state.copyWith(
          status: ProfileStatus.error, errorMessage: e.toString());
    }
  }

  Future<ProfileModel?> updateMyProfile({
    String? nombreArtistico,
    String? disciplina,
    String? biografia,
    File? foto,
    Map<String, String>? redesSociales,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repo.updateMyProfile(
        nombreArtistico: nombreArtistico,
        disciplina: disciplina,
        biografia: biografia,
        foto: foto,
        redesSociales: redesSociales,
      );
      state = state.copyWith(profile: saved, isSaving: false);
      return saved;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> updateProfile({
    required String nombreArtistico,
    required String disciplina,
    String? biografia,
    File? foto,
    Map<String, String>? redesSociales,
  }) async {
    final saved = await updateMyProfile(
      nombreArtistico: nombreArtistico,
      disciplina: disciplina,
      biografia: biografia,
      foto: foto,
      redesSociales: redesSociales,
    );
    return saved != null;
  }

  Future<void> loadPortfolio(int profileId) async {
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    try {
      final items = await _repo.getPortfolio(profileId);
      state = state.copyWith(status: ProfileStatus.success, portfolio: items);
    } catch (e) {
      state = state.copyWith(
          status: ProfileStatus.error, errorMessage: e.toString());
    }
  }

  Future<bool> addPortfolioItem({
    required File file,
    required String tipo,
    String? titulo,
    String? descripcion,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final me = state.profile ?? await _repo.getMyProfile();
      if (me == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'No se pudo cargar tu perfil.',
        );
        return false;
      }

      final created = await _repo.addPortfolioItem(
        profileId: me.id,
        file: file,
        tipo: tipo,
        titulo: titulo?.trim().isEmpty ?? true ? null : titulo?.trim(),
        descripcion:
            descripcion?.trim().isEmpty ?? true ? null : descripcion?.trim(),
      );
      final updated = [...state.portfolio, created]
        ..sort((a, b) => a.orden.compareTo(b.orden));
      state = state.copyWith(portfolio: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deletePortfolioItem(int itemId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final me = state.profile ?? await _repo.getMyProfile();
      if (me == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'No se pudo cargar tu perfil.',
        );
        return false;
      }

      await _repo.deletePortfolioItem(me.id, itemId);
      state = state.copyWith(
        portfolio: state.portfolio.where((e) => e.id != itemId).toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> reorderPortfolio({
    required int profileId,
    required List<PortfolioItemModel> ordered,
  }) async {
    state = state.copyWith(portfolio: ordered);
    for (var i = 0; i < ordered.length; i++) {
      final item = ordered[i];
      if (item.orden == i) continue;
      try {
        await _repo.updatePortfolioItemOrder(
          profileId: profileId,
          itemId: item.id,
          orden: i,
        );
      } catch (_) {}
    }
    await loadPortfolio(profileId);
  }

  Future<ProfileModel?> followArtist(int profileId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.followArtist(profileId);
      state = state.copyWith(isSaving: false);
      return updated;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<ProfileModel?> unfollowArtist(int profileId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.unfollowArtist(profileId);
      state = state.copyWith(isSaving: false);
      return updated;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return null;
    }
  }
}
