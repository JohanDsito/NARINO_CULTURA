import 'package:dio/dio.dart';

/// Traduce los errores de red y HTTP a mensajes para el usuario.
///
/// Reglas comunes a toda la app:
/// - distingue "tiempo agotado" de "sin conexión";
/// - un 5xx nunca muestra lo que mandó el servidor (podría ser HTML o un traceback);
/// - del cuerpo solo se toman mensajes de DRF (`detail`, `non_field_errors`, campos),
///   nunca un texto crudo.
abstract final class ApiError {
  static const sinConexion =
      'Sin conexión con el servidor. Revisa tu internet e intenta de nuevo.';
  static const tiempoAgotado =
      'El servidor tardó demasiado en responder. Revisa tu conexión e intenta de nuevo.';
  static const errorServidor =
      'El servidor tuvo un problema. Intenta de nuevo en unos minutos.';
  static const sesionExpirada = 'Tu sesión expiró. Inicia sesión de nuevo.';
  static const sinPermiso = 'No tienes permiso para realizar esta acción.';
  static const noEncontrado = 'No encontramos lo que buscabas.';
  static const demasiadosIntentos =
      'Hiciste demasiados intentos. Espera unos minutos e intenta de nuevo.';
  static const inesperado = 'Ocurrió un error inesperado. Intenta de nuevo.';

  /// Mensajes más largos que esto no se muestran: no son mensajes para personas.
  static const _maxLength = 200;

  /// `true` si el error es de red (sin respuesta del servidor).
  static bool isNetwork(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          true,
        _ => false,
      };

  /// Mensaje para [e]. [byStatus] permite textos propios por código HTTP
  /// (p. ej. `{404: 'Obra no encontrada.'}`) y tiene prioridad sobre los genéricos.
  static String message(
    DioException e, {
    Map<int, String> byStatus = const {},
    String fallback = inesperado,
  }) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return tiempoAgotado;
      case DioExceptionType.connectionError:
        return sinConexion;
      default:
        break;
    }

    final code = e.response?.statusCode;
    if (code != null && byStatus.containsKey(code)) return byStatus[code]!;
    if (code != null && code >= 500) return errorServidor;

    switch (code) {
      case 401:
        return sesionExpirada;
      case 403:
        return extractMessage(e.response?.data) ?? sinPermiso;
      case 404:
        return noEncontrado;
      case 429:
        return demasiadosIntentos;
    }
    return extractMessage(e.response?.data) ?? fallback;
  }

  /// Primer mensaje legible de una respuesta de error de DRF, o `null`.
  static String? extractMessage(Object? data) {
    if (data is! Map) return null;

    String? clean(Object? value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || text.length > _maxLength) return null;
      return text;
    }

    String? first(Object? value) {
      if (value is List && value.isNotEmpty) return clean(value.first);
      if (value is String) return clean(value);
      return null;
    }

    return first(data['detail']) ??
        first(data['non_field_errors']) ??
        data.values.map(first).firstWhere((m) => m != null, orElse: () => null);
  }
}
