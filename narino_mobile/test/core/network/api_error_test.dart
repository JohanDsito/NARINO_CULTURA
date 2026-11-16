import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/api_error.dart';
import 'package:narino_cultura/features/auth/data/auth_repository.dart';

DioException _network(DioExceptionType type) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
    );

DioException _http(int code, [Object? data]) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: code,
        data: data,
      ),
    );

void main() {
  group('ApiError.message (MO-DISP-03, MO-USA-02)', () {
    test('distingue tiempo agotado de sin conexión', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(ApiError.message(_network(type)), ApiError.tiempoAgotado);
      }
      expect(
        ApiError.message(_network(DioExceptionType.connectionError)),
        ApiError.sinConexion,
      );
    });

    test('un 5xx nunca muestra el cuerpo (HTML o traceback)', () {
      expect(
        ApiError.message(_http(500, '<html><body>Server Error (500)</body></html>')),
        ApiError.errorServidor,
      );
      expect(
        ApiError.message(_http(502, {'detail': 'Traceback (most recent call last): ...'})),
        ApiError.errorServidor,
      );
    });

    test('un cuerpo de texto crudo no se muestra aunque no sea 5xx', () {
      expect(
        ApiError.message(_http(400, 'Bad Request: <script>')),
        ApiError.inesperado,
      );
    });

    test('toma los mensajes de DRF: detail, non_field_errors y campos', () {
      expect(ApiError.message(_http(400, {'detail': 'Obra vendida.'})), 'Obra vendida.');
      expect(
        ApiError.message(_http(400, {
          'non_field_errors': ['Credenciales inválidas.'],
        })),
        'Credenciales inválidas.',
      );
      expect(
        ApiError.message(_http(400, {
          'price': ['Asegúrese de que este valor sea mayor que 0.'],
        })),
        'Asegúrese de que este valor sea mayor que 0.',
      );
    });

    test('ignora mensajes demasiado largos para ser de una persona', () {
      expect(
        ApiError.message(_http(400, {'detail': 'x' * 500})),
        ApiError.inesperado,
      );
    });

    test('los textos propios por código tienen prioridad', () {
      expect(
        ApiError.message(_http(404), byStatus: const {404: 'Obra no encontrada.'}),
        'Obra no encontrada.',
      );
      expect(ApiError.message(_http(404)), ApiError.noEncontrado);
      expect(ApiError.message(_http(401)), ApiError.sesionExpirada);
      expect(ApiError.message(_http(429)), ApiError.demasiadosIntentos);
    });

    test('un 403 usa el mensaje del backend si lo hay', () {
      expect(
        ApiError.message(_http(403, {'detail': 'Solo el dueño puede editarla.'})),
        'Solo el dueño puede editarla.',
      );
      expect(ApiError.message(_http(403)), ApiError.sinPermiso);
    });
  });

  group('AuthRepository.friendlyLoginMessage (MO-USA-02)', () {
    test('credenciales inválidas dice qué hacer', () {
      expect(
        AuthRepository.friendlyLoginMessage('Credenciales inválidas.'),
        contains('¿Olvidaste tu contraseña?'),
      );
    });

    test('correo sin verificar indica abrir el enlace', () {
      expect(
        AuthRepository.friendlyLoginMessage(
            'Debe verificar su email antes de iniciar sesión.'),
        contains('confirma tu correo'),
      );
    });

    test('un mensaje desconocido del backend se muestra tal cual', () {
      expect(AuthRepository.friendlyLoginMessage('Otro motivo.'), 'Otro motivo.');
    });
  });
}
