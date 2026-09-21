import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/auctions/data/auctions_repository.dart';
import 'package:narino_cultura/features/auctions/data/auctions_service.dart';

class _MockAuctionsService extends Mock implements AuctionsService {}

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

Map<String, dynamic> _auctionJson({String id = '1'}) => {
      'id': id,
      'artwork_id': 'obra-$id',
      'obra_titulo': 'Obra $id',
      'artista_nombre': 'Artista',
      'base_price': 1000,
      'current_price': 1200,
      'total_pujas': 1,
      'starts_at': '2025-01-01T00:00:00.000Z',
      'ends_at': '2025-01-10T00:00:00.000Z',
      'status': 'ACTIVA',
      'bids': const [],
    };

void main() {
  late _MockAuctionsService service;
  late AuctionsRepository repo;

  setUp(() {
    service = _MockAuctionsService();
    repo = AuctionsRepository(service: service);
  });

  group('getAuctions', () {
    test('mapea la lista de subastas devuelta por el servicio', () async {
      when(() => service.getAuctions(
            participante: any(named: 'participante'),
            artista: any(named: 'artista'),
            estado: any(named: 'estado'),
          )).thenAnswer(
        (_) async => [_auctionJson(id: '1'), _auctionJson(id: '2')],
      );

      final result = await repo.getAuctions();

      expect(result, hasLength(2));
      expect(result.first.id, '1');
      expect(result.last.id, '2');
    });

    test('ignora elementos que no son mapas en la respuesta', () async {
      when(() => service.getAuctions(
            participante: any(named: 'participante'),
            artista: any(named: 'artista'),
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => [_auctionJson(id: '1'), 'no-es-un-mapa']);

      final result = await repo.getAuctions();

      expect(result, hasLength(1));
    });

    test('propaga los filtros al servicio', () async {
      when(() => service.getAuctions(
            participante: any(named: 'participante'),
            artista: any(named: 'artista'),
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => []);

      await repo.getAuctions(
        participante: 'user-1',
        artista: 'artist-1',
        estado: 'activa',
      );

      verify(() => service.getAuctions(
            participante: 'user-1',
            artista: 'artist-1',
            estado: 'activa',
          )).called(1);
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getAuctions(
            participante: any(named: 'participante'),
            artista: any(named: 'artista'),
            estado: any(named: 'estado'),
          )).thenThrow(_connectionError());

      await expectLater(
        repo.getAuctions(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });

    test('traduce un 401 a un mensaje de sesión expirada', () async {
      when(() => service.getAuctions(
            participante: any(named: 'participante'),
            artista: any(named: 'artista'),
            estado: any(named: 'estado'),
          )).thenThrow(_httpError(401));

      await expectLater(
        repo.getAuctions(),
        throwsA('Tu sesión expiró. Inicia sesión nuevamente.'),
      );
    });
  });

  group('getDetail', () {
    test('mapea el detalle de la subasta', () async {
      when(() => service.getAuctionDetail('1'))
          .thenAnswer((_) async => _auctionJson(id: '1'));

      final result = await repo.getDetail('1');

      expect(result.id, '1');
      expect(result.precioActual, 1200.0);
    });

    test('traduce un 404 a "Subasta no encontrada."', () async {
      when(() => service.getAuctionDetail('999')).thenThrow(_httpError(404));

      await expectLater(
        repo.getDetail('999'),
        throwsA('Subasta no encontrada.'),
      );
    });
  });

  group('createAuction', () {
    test('mapea la subasta creada', () async {
      when(() => service.createAuction(
            obraId: any(named: 'obraId'),
            precioBase: any(named: 'precioBase'),
            duracionDias: any(named: 'duracionDias'),
            fechaInicio: any(named: 'fechaInicio'),
          )).thenAnswer((_) async => _auctionJson(id: '5'));

      final result = await repo.createAuction(
        obraId: 'obra-5',
        precioBase: 5000,
        duracionDias: 7,
        fechaInicio: DateTime(2025, 2, 1),
      );

      expect(result.id, '5');
    });

    test('extrae el primer mensaje de error de un 400 con detalle de campo',
        () async {
      when(() => service.createAuction(
            obraId: any(named: 'obraId'),
            precioBase: any(named: 'precioBase'),
            duracionDias: any(named: 'duracionDias'),
            fechaInicio: any(named: 'fechaInicio'),
          )).thenThrow(_httpError(400, data: {
            'base_price': ['Este campo es requerido.'],
          }));

      await expectLater(
        repo.createAuction(
          obraId: 'obra-5',
          precioBase: 0,
          duracionDias: 7,
          fechaInicio: DateTime(2025, 2, 1),
        ),
        throwsA('Este campo es requerido.'),
      );
    });

    test('usa el "detail" del body cuando está presente', () async {
      when(() => service.createAuction(
            obraId: any(named: 'obraId'),
            precioBase: any(named: 'precioBase'),
            duracionDias: any(named: 'duracionDias'),
            fechaInicio: any(named: 'fechaInicio'),
          )).thenThrow(_httpError(400, data: {
            'detail': 'La obra ya tiene una subasta activa.',
          }));

      await expectLater(
        repo.createAuction(
          obraId: 'obra-5',
          precioBase: 0,
          duracionDias: 7,
          fechaInicio: DateTime(2025, 2, 1),
        ),
        throwsA('La obra ya tiene una subasta activa.'),
      );
    });

    test('devuelve un mensaje genérico cuando no hay body ni detalle',
        () async {
      when(() => service.createAuction(
            obraId: any(named: 'obraId'),
            precioBase: any(named: 'precioBase'),
            duracionDias: any(named: 'duracionDias'),
            fechaInicio: any(named: 'fechaInicio'),
          )).thenThrow(_httpError(500));

      await expectLater(
        repo.createAuction(
          obraId: 'obra-5',
          precioBase: 0,
          duracionDias: 7,
          fechaInicio: DateTime(2025, 2, 1),
        ),
        throwsA('Ocurrió un error inesperado.'),
      );
    });
  });

  group('bid', () {
    test('llama al servicio con el monto y auctionId indicados', () async {
      when(() => service.bid(
            auctionId: any(named: 'auctionId'),
            monto: any(named: 'monto'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await repo.bid(auctionId: 'auction-1', monto: 2000);

      verify(() => service.bid(auctionId: 'auction-1', monto: 2000))
          .called(1);
    });

    test('traduce un 403 con mensaje del backend', () async {
      when(() => service.bid(
            auctionId: any(named: 'auctionId'),
            monto: any(named: 'monto'),
          )).thenThrow(_httpError(403, data: {
            'detail': 'No puedes pujar en tu propia subasta.',
          }));

      await expectLater(
        repo.bid(auctionId: 'auction-1', monto: 2000),
        throwsA('No puedes pujar en tu propia subasta.'),
      );
    });

    test('traduce un 403 sin body a mensaje de permiso por defecto', () async {
      when(() => service.bid(
            auctionId: any(named: 'auctionId'),
            monto: any(named: 'monto'),
          )).thenThrow(_httpError(403));

      await expectLater(
        repo.bid(auctionId: 'auction-1', monto: 2000),
        throwsA('No tienes permiso para realizar esta acción.'),
      );
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.bid(
            auctionId: any(named: 'auctionId'),
            monto: any(named: 'monto'),
          )).thenThrow(_connectionError());

      await expectLater(
        repo.bid(auctionId: 'auction-1', monto: 2000),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });
}
