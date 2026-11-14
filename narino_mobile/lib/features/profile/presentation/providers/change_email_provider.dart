import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account_security_repository.dart';
import 'account_security_provider.dart';

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
