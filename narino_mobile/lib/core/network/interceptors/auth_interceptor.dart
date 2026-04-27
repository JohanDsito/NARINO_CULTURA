import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../utils/storage_utils.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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

    if (status == 401 && !alreadyRetried) {
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

      final response = await Dio().post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refresh': refreshToken},
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
