import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_repository.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_service.dart';

class _MockMarketplaceService extends Mock implements MarketplaceService {}

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
      type: DioExceptionType.connectionTimeout,
    );

Map<String, dynamic> _cartItemJson({String id = '1'}) => {
      'id': id,
      'artwork': 'obra-$id',
      'artwork_title': 'Obra $id',
      'artista_nombre': 'Artista',
      'artwork_price': '100000',
    };

Map<String, dynamic> _favoriteJson({String id = '1'}) => {
      'id': id,
      'artwork_id': 'obra-$id',
      'artwork_title': 'Obra $id',
      'status': 'available',
    };

Map<String, dynamic> _orderJson({String id = '1'}) => {
      'id': id,
      'status': 'PENDIENTE',
      'total_amount': '100000',
      'created_at': '2025-01-01T00:00:00.000Z',
      'items': const [],
    };

void main() {
  late _MockMarketplaceService service;
  late MarketplaceRepository repo;

  setUp(() {
    service = _MockMarketplaceService();
    repo = MarketplaceRepository(service: service);
  });

  group('getCart', () {
    test('mapea la lista de items del carrito', () async {
      when(() => service.getCart()).thenAnswer(
        (_) async => [_cartItemJson(id: '1'), _cartItemJson(id: '2')],
      );

      final result = await repo.getCart();

      expect(result, hasLength(2));
      expect(result.first.obraId, 'obra-1');
      expect(result.first.precio, 100000);
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getCart()).thenThrow(_connectionError());

      await expectLater(
        repo.getCart(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });

    test('extrae el detalle de un 400 cuando el backend lo envía', () async {
      when(() => service.getCart())
          .thenThrow(_httpError(400, data: {'detail': 'Carrito bloqueado.'}));

      await expectLater(
        repo.getCart(),
        throwsA('Carrito bloqueado.'),
      );
    });

    test('usa un mensaje genérico en un 400 sin detalle', () async {
      when(() => service.getCart()).thenThrow(_httpError(400));

      await expectLater(
        repo.getCart(),
        throwsA('Esta obra no está disponible.'),
      );
    });

    test('traduce un 403 a un mensaje de permisos', () async {
      when(() => service.getCart()).thenThrow(_httpError(403));

      await expectLater(
        repo.getCart(),
        throwsA('No tienes permiso para esta acción.'),
      );
    });

    test('traduce un 404 a elemento no encontrado', () async {
      when(() => service.getCart()).thenThrow(_httpError(404));

      await expectLater(
        repo.getCart(),
        throwsA('Elemento no encontrado.'),
      );
    });

    test('traduce un error inesperado a un mensaje genérico', () async {
      when(() => service.getCart()).thenThrow(_httpError(500));

      await expectLater(
        repo.getCart(),
        throwsA('Error inesperado. Intenta de nuevo.'),
      );
    });
  });

  group('addToCart', () {
    test('delega en el servicio con el id de la obra', () async {
      when(() => service.addToCart('obra-1')).thenAnswer((_) async {});

      await repo.addToCart('obra-1');

      verify(() => service.addToCart('obra-1')).called(1);
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.addToCart('obra-1')).thenThrow(_httpError(400));

      await expectLater(
        repo.addToCart('obra-1'),
        throwsA('Esta obra no está disponible.'),
      );
    });
  });

  group('removeFromCart', () {
    test('delega en el servicio con el id de la obra', () async {
      when(() => service.removeFromCart('obra-1')).thenAnswer((_) async {});

      await repo.removeFromCart('obra-1');

      verify(() => service.removeFromCart('obra-1')).called(1);
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.removeFromCart('obra-1')).thenThrow(_httpError(404));

      await expectLater(
        repo.removeFromCart('obra-1'),
        throwsA('Elemento no encontrado.'),
      );
    });
  });

  group('clearCart', () {
    test('delega en el servicio', () async {
      when(() => service.clearCart()).thenAnswer((_) async {});

      await repo.clearCart();

      verify(() => service.clearCart()).called(1);
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.clearCart()).thenThrow(_connectionError());

      await expectLater(
        repo.clearCart(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });

  group('getFavorites', () {
    test('mapea la lista de favoritos', () async {
      when(() => service.getFavorites()).thenAnswer(
        (_) async => [_favoriteJson(id: '1'), _favoriteJson(id: '2')],
      );

      final result = await repo.getFavorites();

      expect(result, hasLength(2));
      expect(result.first.obraId, 'obra-1');
      expect(result.first.estado, 'available'.toLowerCase());
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.getFavorites()).thenThrow(_httpError(500));

      await expectLater(
        repo.getFavorites(),
        throwsA('Error inesperado. Intenta de nuevo.'),
      );
    });
  });

  group('addFavorite', () {
    test('delega en el servicio con el id de la obra', () async {
      when(() => service.addFavorite('obra-1')).thenAnswer((_) async {});

      await repo.addFavorite('obra-1');

      verify(() => service.addFavorite('obra-1')).called(1);
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.addFavorite('obra-1')).thenThrow(_httpError(403));

      await expectLater(
        repo.addFavorite('obra-1'),
        throwsA('No tienes permiso para esta acción.'),
      );
    });
  });

  group('removeFavorite', () {
    test('delega en el servicio con el id de la obra', () async {
      when(() => service.removeFavorite('obra-1')).thenAnswer((_) async {});

      await repo.removeFavorite('obra-1');

      verify(() => service.removeFavorite('obra-1')).called(1);
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.removeFavorite('obra-1')).thenThrow(_httpError(404));

      await expectLater(
        repo.removeFavorite('obra-1'),
        throwsA('Elemento no encontrado.'),
      );
    });
  });

  group('createOrder', () {
    test('mapea la orden creada', () async {
      when(() => service.createOrder())
          .thenAnswer((_) async => _orderJson(id: '1'));

      final order = await repo.createOrder();

      expect(order.id, '1');
      expect(order.estado, 'pendiente');
      expect(order.total, 100000);
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.createOrder()).thenThrow(_httpError(400));

      await expectLater(
        repo.createOrder(),
        throwsA('Esta obra no está disponible.'),
      );
    });
  });

  group('getOrders', () {
    test('mapea la lista de órdenes', () async {
      when(() => service.getOrders()).thenAnswer(
        (_) async => [_orderJson(id: '1'), _orderJson(id: '2')],
      );

      final result = await repo.getOrders();

      expect(result, hasLength(2));
      expect(result.first.id, '1');
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.getOrders()).thenThrow(_connectionError());

      await expectLater(
        repo.getOrders(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });

  group('getOrderDetail', () {
    test('mapea el detalle de la orden', () async {
      when(() => service.getOrderDetail('1'))
          .thenAnswer((_) async => _orderJson(id: '1'));

      final order = await repo.getOrderDetail('1');

      expect(order.id, '1');
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.getOrderDetail('1')).thenThrow(_httpError(404));

      await expectLater(
        repo.getOrderDetail('1'),
        throwsA('Elemento no encontrado.'),
      );
    });
  });

  group('initiatePayment', () {
    test('construye la URL de checkout de Wompi con los datos de la respuesta',
        () async {
      when(() => service.initiatePayment('order-1')).thenAnswer((_) async => {
            'public_key': 'pub_test_123',
            'reference': 'ref-abc',
            'amount_in_cents': '10000000',
            'currency': 'COP',
            'integrity_signature': 'sig-xyz',
          });

      final url = await repo.initiatePayment('order-1');

      expect(url, contains('https://checkout.wompi.co/p/'));
      expect(url, contains('public-key=pub_test_123'));
      expect(url, contains('currency=COP'));
      expect(url, contains('amount-in-cents=10000000'));
      expect(url, contains('reference=ref-abc'));
      expect(url, contains('signature:integrity=sig-xyz'));
    });

    test('devuelve cadena vacía si faltan public_key o reference', () async {
      when(() => service.initiatePayment('order-1'))
          .thenAnswer((_) async => {'currency': 'COP'});

      final url = await repo.initiatePayment('order-1');

      expect(url, '');
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.initiatePayment('order-1')).thenThrow(_httpError(400));

      await expectLater(
        repo.initiatePayment('order-1'),
        throwsA('Esta obra no está disponible.'),
      );
    });
  });

  group('getPaymentStatus', () {
    test('devuelve el status de la respuesta', () async {
      when(() => service.getPaymentStatus('order-1'))
          .thenAnswer((_) async => {'status': 'completado'});

      final status = await repo.getPaymentStatus('order-1');

      expect(status, 'completado');
    });

    test('devuelve unknown cuando la respuesta no trae status', () async {
      when(() => service.getPaymentStatus('order-1'))
          .thenAnswer((_) async => <String, dynamic>{});

      final status = await repo.getPaymentStatus('order-1');

      expect(status, 'unknown');
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.getPaymentStatus('order-1'))
          .thenThrow(_httpError(403));

      await expectLater(
        repo.getPaymentStatus('order-1'),
        throwsA('No tienes permiso para esta acción.'),
      );
    });
  });

  group('getPurchaseHistory', () {
    test('mapea la lista de órdenes de compra', () async {
      when(() => service.getPurchaseHistory()).thenAnswer(
        (_) async => [_orderJson(id: '1')],
      );

      final result = await repo.getPurchaseHistory();

      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.getPurchaseHistory()).thenThrow(_httpError(500));

      await expectLater(
        repo.getPurchaseHistory(),
        throwsA('Error inesperado. Intenta de nuevo.'),
      );
    });
  });

  group('getSalesHistory', () {
    test('mapea la lista de órdenes de venta', () async {
      when(() => service.getSalesHistory()).thenAnswer(
        (_) async => [_orderJson(id: '1'), _orderJson(id: '2')],
      );

      final result = await repo.getSalesHistory();

      expect(result, hasLength(2));
    });

    test('propaga el mensaje de error del servicio', () async {
      when(() => service.getSalesHistory()).thenThrow(_connectionError());

      await expectLater(
        repo.getSalesHistory(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });
}
