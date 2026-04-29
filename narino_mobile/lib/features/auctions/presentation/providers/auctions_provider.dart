import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../artworks/data/artwork_repository.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/auctions_repository.dart';
import '../../domain/auction_model.dart';

final auctionsRepositoryProvider =
    Provider<AuctionsRepository>((ref) => AuctionsRepository());

final artworkRepositoryProviderForAuctions =
    Provider<ArtworkRepository>((ref) => ArtworkRepository());

final auctionsProvider =
    StateNotifierProvider<AuctionsNotifier, AsyncValue<List<AuctionModel>>>(
  (ref) => AuctionsNotifier(ref.read(auctionsRepositoryProvider)),
);

final auctionDetailProvider =
    FutureProvider.family.autoDispose<AuctionModel, int>((ref, id) async {
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
  if (myProfile == null) {
    throw 'No se pudo cargar tu perfil.';
  }
  final myId = myProfile.id;

  final result =
      await ref.read(artworkRepositoryProviderForAuctions).getCatalog(
            page: 1,
          );
  final list = result.artworks;

  var filtered = list.where((a) => a.isDisponible).toList();
  filtered = filtered.where((a) => a.artistaId == myId).toList();

  filtered.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
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
