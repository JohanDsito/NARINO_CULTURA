import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/data/artwork_service.dart';

class _MockArtworkService extends Mock implements ArtworkService {}

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

Map<String, dynamic> _artworkJson({String id = '1'}) => {
      'id': id,
      'title': 'Obra $id',
      'description': '',
      'category': '1',
      'status': 'available',
      'artist': 'artist-1',
      'artista_nombre': 'Artista',
      'created_at': '2025-01-01T00:00:00.000Z',
      'images': const [],
    };

void main() {
  late _MockArtworkService service;
  late ArtworkRepository repo;

  setUp(() {
    service = _MockArtworkService();
    repo = ArtworkRepository(service: service);
  });

  group('getCatalog', () {
    test('mapea resultados y total desde la respuesta paginada', () async {
      when(() => service.getCatalog(
            search: any(named: 'search'),
            categoria: any(named: 'categoria'),
            tecnica: any(named: 'tecnica'),
            precioMin: any(named: 'precioMin'),
            precioMax: any(named: 'precioMax'),
            ordenarPor: any(named: 'ordenarPor'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => {
            'results': [_artworkJson(id: '1'), _artworkJson(id: '2')],
            'count': 2,
          });

      final result = await repo.getCatalog();

      expect(result.artworks, hasLength(2));
      expect(result.total, 2);
      expect(result.artworks.first.id, '1');
    });

    test('usa la cantidad de resultados como total si count no es un int',
        () async {
      when(() => service.getCatalog(
            search: any(named: 'search'),
            categoria: any(named: 'categoria'),
            tecnica: any(named: 'tecnica'),
            precioMin: any(named: 'precioMin'),
            precioMax: any(named: 'precioMax'),
            ordenarPor: any(named: 'ordenarPor'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => {
            'results': [_artworkJson()],
          });

      final result = await repo.getCatalog();

      expect(result.total, 1);
    });

    test('traduce un 404 a un mensaje entendible', () async {
      when(() => service.getCatalog(
            search: any(named: 'search'),
            categoria: any(named: 'categoria'),
            tecnica: any(named: 'tecnica'),
            precioMin: any(named: 'precioMin'),
            precioMax: any(named: 'precioMax'),
            ordenarPor: any(named: 'ordenarPor'),
            page: any(named: 'page'),
          )).thenThrow(_httpError(404));

      await expectLater(
        repo.getCatalog(),
        throwsA('Obra no encontrada.'),
      );
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getCatalog(
            search: any(named: 'search'),
            categoria: any(named: 'categoria'),
            tecnica: any(named: 'tecnica'),
            precioMin: any(named: 'precioMin'),
            precioMax: any(named: 'precioMax'),
            ordenarPor: any(named: 'ordenarPor'),
            page: any(named: 'page'),
          )).thenThrow(_connectionError());

      await expectLater(
        repo.getCatalog(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });

    test('extrae el primer mensaje de error de un 400 con detalle de campo',
        () async {
      when(() => service.getCatalog(
            search: any(named: 'search'),
            categoria: any(named: 'categoria'),
            tecnica: any(named: 'tecnica'),
            precioMin: any(named: 'precioMin'),
            precioMax: any(named: 'precioMax'),
            ordenarPor: any(named: 'ordenarPor'),
            page: any(named: 'page'),
          )).thenThrow(_httpError(400, data: {
            'price': ['Este campo es requerido.'],
          }));

      await expectLater(
        repo.getCatalog(),
        throwsA('Este campo es requerido.'),
      );
    });
  });

  group('getCategories', () {
    test('mapea la lista de categorías', () async {
      when(() => service.getCategories()).thenAnswer((_) async => [
            {'id': 1, 'name': 'Pintura', 'slug': 'pintura'},
            {'id': 2, 'name': 'Escultura', 'slug': 'escultura'},
          ]);

      final categories = await repo.getCategories();

      expect(categories, hasLength(2));
      expect(categories.first.name, 'Pintura');
    });
  });

  group('getByArtist', () {
    test('devuelve lista vacía sin llamar al servicio si el slug es vacío',
        () async {
      final result = await repo.getByArtist('');

      expect(result, isEmpty);
      verifyNever(() => service.getByArtist(any()));
    });

    test('mapea las obras del artista', () async {
      when(() => service.getByArtist('ana-diaz'))
          .thenAnswer((_) async => [_artworkJson(id: '1')]);

      final result = await repo.getByArtist('ana-diaz');

      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });
  });

  group('toggleFavorite', () {
    test('mapea es_favorito y cantidad_favoritos de la respuesta', () async {
      when(() => service.toggleFavorite('1')).thenAnswer((_) async => {
            'es_favorito': true,
            'cantidad_favoritos': 5,
          });

      final result = await repo.toggleFavorite('1');

      expect(result.esFavorito, isTrue);
      expect(result.cantidad, 5);
    });
  });

  group('delete', () {
    test('propaga el mensaje de error cuando no se tiene permiso', () async {
      when(() => service.deleteArtwork('1')).thenThrow(_httpError(403));

      await expectLater(
        repo.delete('1'),
        throwsA('No tienes permiso para realizar esta acción.'),
      );
    });
  });
}
