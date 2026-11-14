import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account_security_repository.dart';
import 'account_security_provider.dart';

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

  Future<void> revokeSession(String id) async {
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
