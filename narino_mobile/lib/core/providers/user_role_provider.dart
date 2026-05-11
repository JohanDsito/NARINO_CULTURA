import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../utils/storage_utils.dart';

class CurrentUserClaims {
  const CurrentUserClaims({required this.role, required this.userId});

  final String? role;
  final int? userId;
}

final currentUserClaimsProvider = FutureProvider<CurrentUserClaims>((
  ref,
) async {
  final token = await StorageUtils.getAccessToken();
  if (token == null || token.isEmpty) {
    return const CurrentUserClaims(role: null, userId: null);
  }

  String? role;
  int? userId;

  try {
    final parts = token.split('.');
    if (parts.length >= 2) {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        final roleValue =
            json['rol'] ??
            json['role'] ??
            json['user_role'] ??
            json['userRole'];
        role = roleValue?.toString();

        final idValue =
            json['user_id'] ?? json['userId'] ?? json['id'] ?? json['sub'];
        if (idValue != null) {
          userId = int.tryParse(idValue.toString());
        }
      }
    }
  } catch (_) {}

  if (role != null && userId != null) {
    return CurrentUserClaims(role: role, userId: userId);
  }

  try {
    final response = await ApiClient.instance.dio.get('/auth/me/');
    final data = response.data;
    if (data is Map) {
      final roleValue = data['rol'] ?? data['role'];
      final idValue = data['id'] ?? data['user_id'] ?? data['userId'];
      return CurrentUserClaims(
        role: role ?? roleValue?.toString(),
        userId: userId ?? int.tryParse(idValue?.toString() ?? ''),
      );
    }
  } catch (_) {}

  return CurrentUserClaims(role: role, userId: userId);
});

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final claims = await ref.watch(currentUserClaimsProvider.future);
  return claims.role;
});

final currentUserIdProvider = FutureProvider<int?>((ref) async {
  final claims = await ref.watch(currentUserClaimsProvider.future);
  return claims.userId;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(currentUserRoleProvider.future);
  return role == 'admin';
});
