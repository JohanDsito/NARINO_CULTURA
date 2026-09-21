import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/storage_utils.dart';
import 'auth_provider.dart';

final isAuthenticatedProvider = FutureProvider.autoDispose<bool>((ref) async {
  return StorageUtils.hasToken();
});

final isEmailVerifiedProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final user = await ref.read(authRepositoryProvider).getMe();
    return user.isVerified;
  } catch (_) {
    return true;
  }
});
