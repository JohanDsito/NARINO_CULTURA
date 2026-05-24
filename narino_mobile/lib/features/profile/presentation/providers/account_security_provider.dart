import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/storage_utils.dart';
import '../../../auctions/data/auctions_repository.dart';
import '../../../auctions/presentation/providers/auctions_provider.dart';
import '../../data/account_security_repository.dart';

final accountSecurityRepositoryProvider =
    Provider<AccountSecurityRepository>((ref) => AccountSecurityRepository());

final changeEmailProvider =
    StateNotifierProvider<ChangeEmailNotifier, AsyncValue<void>>(
  (ref) => ChangeEmailNotifier(ref.read(accountSecurityRepositoryProvider)),
);

class ChangeEmailNotifier extends StateNotifier<AsyncValue<void>> {
  ChangeEmailNotifier(this._repo) : super(const AsyncValue.data(null));

  final AccountSecurityRepository _repo;

  Future<void> submit({
    required String newEmail,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.changeEmail(newEmail: newEmail, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final activeSessionsProvider = StateNotifierProvider<ActiveSessionsNotifier,
    AsyncValue<List<ActiveSessionModel>>>(
  (ref) => ActiveSessionsNotifier(ref.read(accountSecurityRepositoryProvider)),
);

class ActiveSessionsNotifier
    extends StateNotifier<AsyncValue<List<ActiveSessionModel>>> {
  ActiveSessionsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final AccountSecurityRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getActiveSessions();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> revokeSession(int id) async {
    final current = state.valueOrNull ?? const <ActiveSessionModel>[];
    state = AsyncValue.data(current);
    try {
      await _repo.revokeSession(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> revokeOtherSessions() async {
    final current = state.valueOrNull ?? const <ActiveSessionModel>[];
    state = AsyncValue.data(current);
    try {
      await _repo.revokeOtherSessions();
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final deleteAccountProvider =
    StateNotifierProvider<DeleteAccountNotifier, AsyncValue<void>>(
  (ref) => DeleteAccountNotifier(
    ref.read(accountSecurityRepositoryProvider),
    ref.read(auctionsRepositoryProvider),
  ),
);

class DeleteAccountNotifier extends StateNotifier<AsyncValue<void>> {
  DeleteAccountNotifier(this._repo, this._auctionsRepo)
      : super(const AsyncValue.data(null));

  final AccountSecurityRepository _repo;
  final AuctionsRepository _auctionsRepo;

  Future<void> submit({required String password}) async {
    state = const AsyncValue.loading();
    try {
      // Check active auctions only for artistas; silently skip for any API error
      try {
        final activeAuctions =
            await _auctionsRepo.getAuctions(artista: 'me', estado: 'activa');
        if (activeAuctions.isNotEmpty) {
          state = AsyncValue.error(
            'No puedes eliminar tu cuenta mientras tengas subastas activas.',
            StackTrace.current,
          );
          return;
        }
      } catch (_) {
        // Endpoint unavailable, 403 for non-artistas, etc. — proceed with deletion.
      }

      await _repo.deleteAccount(password: password);
      await StorageUtils.clearTokens();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
