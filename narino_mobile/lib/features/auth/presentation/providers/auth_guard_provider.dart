import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/storage_utils.dart';

final isAuthenticatedProvider = FutureProvider.autoDispose<bool>((ref) async {
  return StorageUtils.hasToken();
});
