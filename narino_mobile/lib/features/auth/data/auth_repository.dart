import '../../../core/utils/storage_utils.dart';
import '../domain/user_model.dart';
import 'auth_service.dart';

class AuthRepository {
  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final tokens = await _service.login(email: email, password: password);

    final access = tokens['access']?.toString();
    final refresh = tokens['refresh']?.toString();

    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw const FormatException('Respuesta inválida del servidor (tokens).');
    }

    await StorageUtils.saveTokens(accessToken: access, refreshToken: refresh);
  }

  Future<UserModel> register({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    final json = await _service.register(
      nombre: nombre,
      email: email,
      password: password,
      rol: rol,
    );

    final user = UserModel.fromJson(json);
    await login(email: email, password: password);
    return user;
  }

  Future<void> logout() => StorageUtils.clearTokens();

  Future<bool> hasToken() => StorageUtils.hasToken();
}
