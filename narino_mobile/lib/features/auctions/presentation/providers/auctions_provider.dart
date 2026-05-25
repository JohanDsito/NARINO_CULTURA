import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../artworks/domain/artwork_model.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/auctions_repository.dart';
import '../../domain/auction_model.dart';

final auctionsRepositoryProvider =
    Provider<AuctionsRepository>((ref) => AuctionsRepository());


final auctionsProvider =
    StateNotifierProvider<AuctionsNotifier, AsyncValue<List<AuctionModel>>>(
  (ref) => AuctionsNotifier(ref.read(auctionsRepositoryProvider)),
);

final auctionDetailProvider =
    FutureProvider.family.autoDispose<AuctionModel, String>((ref, id) async {
  return ref.read(auctionsRepositoryProvider).getDetail(id);
});

class AuctionHistoryParams {
  final String mode;
  final String? estado;

  const AuctionHistoryParams({required this.mode, this.estado});

  @override
  bool operator ==(Object other) {
    return other is AuctionHistoryParams &&
        other.mode == mode &&
        other.estado == estado;
  }

  @override
  int get hashCode => Object.hash(mode, estado);
}

final auctionHistoryProvider =
    FutureProvider.family.autoDispose<List<AuctionModel>, AuctionHistoryParams>(
  (ref, params) async {
    if (params.mode == 'participante') {
      return ref.read(auctionsRepositoryProvider).getAuctions(
            participante: 'me',
            estado: params.estado,
          );
    }
    return ref.read(auctionsRepositoryProvider).getAuctions(
          artista: 'me',
          estado: params.estado,
        );
  },
);

final myArtworksForAuctionProvider =
    FutureProvider.autoDispose<List<ArtworkModel>>((ref) async {
  final profileState = ref.read(profileProvider);
  final myProfile = profileState.profile ??
      await ref.read(profileRepositoryProvider).getMyProfile();
  if (myProfile == null) throw 'No se pudo cargar tu perfil.';

  // myProfile.id is the artist slug (ProfileModel maps json['slug'] → id)
  final slug = myProfile.id;
  if (slug.isEmpty) throw 'No tienes perfil de artista configurado.';

  // Reutiliza artistArtworksProvider que pagina todos los resultados por slug
  final all = await ref.read(artistArtworksProvider(slug).future);
  final filtered = all.where((a) => a.isDisponible).toList()
    ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  return filtered;
});

class AuctionsNotifier extends StateNotifier<AsyncValue<List<AuctionModel>>> {
  AuctionsNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadActive();
  }

  final AuctionsRepository _repo;

  Future<void> loadActive() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getAuctions(estado: 'activa')
        ..sort((a, b) => a.fechaCierre.compareTo(b.fechaCierre));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
