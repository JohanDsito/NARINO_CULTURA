import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/storage_utils.dart';

final isAuthenticatedProvider = FutureProvider.autoDispose<bool>((ref) async {
  return StorageUtils.hasToken();
});

final isEmailVerifiedProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final response = await ApiClient.instance.dio.get(ApiConstants.myProfile);
    final data = response.data;
    if (data is Map) {
      final v = data['email_verificado'] ?? data['email_verified'];
      if (v is bool) return v;
    }
    return true;
  } catch (_) {
    return true;
  }
});
