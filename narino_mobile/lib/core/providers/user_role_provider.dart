import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../utils/storage_utils.dart';

class CurrentUserClaims {
  const CurrentUserClaims({required this.role, required this.userId});

  /// Rol normalizado: `artista`, `comprador`, `gestor` o `admin`.
  final String? role;

  /// Id del usuario (UUID en el backend).
  final String? userId;
}

/// El backend envía `ARTISTA`, `COMPRADOR`, `GESTOR_CULTURAL` y
/// `ADMINISTRADOR`; la app compara con `artista`, `comprador`, `gestor` y
/// `admin`.
String? normalizeRole(Object? raw) {
  final r = raw?.toString().trim().toLowerCase();
  if (r == null || r.isEmpty) return null;
  return switch (r) {
    'administrador' || 'administrator' => 'admin',
    'gestor_cultural' || 'gestor cultural' => 'gestor',
    _ => r,
  };
}

String? _id(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty || s == 'null') ? null : s;
}

final currentUserClaimsProvider = FutureProvider<CurrentUserClaims>((
  ref,
) async {
  final token = await StorageUtils.getAccessToken();
  if (token == null || token.isEmpty) {
    return const CurrentUserClaims(role: null, userId: null);
  }

  String? role;
  String? userId;

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
        role = normalizeRole(roleValue);

        final idValue =
            json['user_id'] ?? json['userId'] ?? json['id'] ?? json['sub'];
        userId = _id(idValue);
      }
    }
  } catch (_) {}

  if (role != null && userId != null) {
    return CurrentUserClaims(role: role, userId: userId);
  }

  try {
    final response = await ApiClient.instance.dio.get('/api/v1/users/me/');
    final data = response.data;
    if (data is Map) {
      final roleValue = data['role'] ?? data['rol'];
      final idValue = data['id'] ?? data['user_id'] ?? data['userId'];
      return CurrentUserClaims(
        role: role ?? normalizeRole(roleValue),
        userId: userId ?? _id(idValue),
      );
    }
  } catch (_) {}

  return CurrentUserClaims(role: role, userId: userId);
});

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final claims = await ref.watch(currentUserClaimsProvider.future);
  return claims.role;
});

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final claims = await ref.watch(currentUserClaimsProvider.future);
  return claims.userId;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(currentUserRoleProvider.future);
  return role == 'admin';
});
