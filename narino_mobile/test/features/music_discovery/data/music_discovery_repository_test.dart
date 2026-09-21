import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/music_discovery/data/music_discovery_repository.dart';
import 'package:narino_cultura/features/music_discovery/data/music_discovery_service.dart';

class _MockMusicDiscoveryService extends Mock implements MusicDiscoveryService {}

/// Construye un [DioException] como el que lanzaría Dio ante una respuesta
/// HTTP con [statusCode], para probar el manejo de errores del repositorio.
DioException _httpError(int statusCode, {Object? data}) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

DioException _connectionError() => DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );

Map<String, dynamic> _musicianJson({String slug = 'juan-perez'}) => {
      'slug': slug,
      'artistic_name': 'Juan Pérez',
      'genres': ['Salsa'],
      'followers_count': 10,
    };

void main() {
  late _MockMusicDiscoveryService service;
  late MusicDiscoveryRepository repo;

  setUp(() {
    service = _MockMusicDiscoveryService();
    repo = MusicDiscoveryRepository(service: service);
  });

  group('getRecommendations', () {
    test('mapea la lista de músicos recomendados devuelta por el service',
        () async {
      when(() => service.getRecommendations('salsa')).thenAnswer(
        (_) async => [_musicianJson(slug: 'a'), _musicianJson(slug: 'b')],
      );

      final result = await repo.getRecommendations('salsa');

      expect(result, hasLength(2));
      expect(result.first.slug, 'a');
      expect(result.first.name, 'Juan Pérez');
    });

    test('ignora los elementos de la lista que no son mapas', () async {
      when(() => service.getRecommendations('salsa')).thenAnswer(
        (_) async => [_musicianJson(), 'no-es-un-mapa', 42],
      );

      final result = await repo.getRecommendations('salsa');

      expect(result, hasLength(1));
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getRecommendations('salsa'))
          .thenThrow(_connectionError());

      await expectLater(
        repo.getRecommendations('salsa'),
        throwsA('No se pudo conectar al servidor.'),
      );
    });

    test(
        'usa el "detail" del backend como mensaje de error cuando viene en la respuesta',
        () async {
      when(() => service.getRecommendations('salsa')).thenThrow(
        _httpError(400, data: {'detail': 'Consulta inválida.'}),
      );

      await expectLater(
        repo.getRecommendations('salsa'),
        throwsA('Consulta inválida.'),
      );
    });

    test('usa un mensaje genérico cuando el error no trae "detail"',
        () async {
      when(() => service.getRecommendations('salsa'))
          .thenThrow(_httpError(500));

      await expectLater(
        repo.getRecommendations('salsa'),
        throwsA('Error al obtener recomendaciones.'),
      );
    });
  });
}
