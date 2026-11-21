import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Utilidad de almacenamiento seguro para credenciales de autenticación.
///
/// Guarda y recupera el token de acceso y refresh usando `flutter_secure_storage`.
class StorageUtils {
  StorageUtils._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_access_token';
  static const _refreshKey = 'jwt_refresh_token';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() => _storage.read(key: _tokenKey);

  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }
}
