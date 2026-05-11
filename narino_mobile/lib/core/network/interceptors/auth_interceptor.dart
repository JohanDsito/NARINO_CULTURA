import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../utils/storage_utils.dart';

/// Interceptor de autenticación que adjunta el JWT a cada request y gestiona
/// el refresh automático del token cuando el backend responde 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['__skipAuth'] == true;
    final isRefreshCall = options.path == ApiConstants.refreshToken;

    if (skipAuth || isRefreshCall) {
      handler.next(options);
      return;
    }

    final token = await StorageUtils.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['__retried'] == true;
    final skipAuthRefresh =
        err.requestOptions.extra['__skipAuthRefresh'] == true;
    final isRefreshCall = err.requestOptions.path == ApiConstants.refreshToken;

    if (status == 401 &&
        !alreadyRetried &&
        !skipAuthRefresh &&
        !isRefreshCall) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await StorageUtils.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final opts = err.requestOptions;
          opts.extra['__retried'] = true;
          opts.headers['Authorization'] = 'Bearer $newToken';

          try {
            final response = await _dio.fetch(opts);
            handler.resolve(response);
            return;
          } catch (_) {}
        }
      }

      await StorageUtils.clearTokens();
    }

    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await StorageUtils.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh': refreshToken},
        options: Options(
          extra: const {'__skipAuth': true, '__skipAuthRefresh': true},
        ),
      );

      final data = response.data;
      if (data is! Map) return false;

      final newAccess = data['access']?.toString();
      if (newAccess == null || newAccess.isEmpty) return false;

      await StorageUtils.saveTokens(
        accessToken: newAccess,
        refreshToken: refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
