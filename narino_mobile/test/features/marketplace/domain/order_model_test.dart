import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/marketplace/domain/order_model.dart';

void main() {
  group('OrderItemModel.fromJson', () {
    test('mapea los campos en inglés del backend', () {
      final item = OrderItemModel.fromJson({
        'artwork': 'obra-1',
        'artwork_title': 'Barniz de Pasto',
        'artista_nombre': 'Ana Díaz',
        'price': '150000',
        'imagen_url': 'https://cdn.test/1.jpg',
      });

      expect(item.obraId, 'obra-1');
      expect(item.obraTitulo, 'Barniz de Pasto');
      expect(item.artistaNombre, 'Ana Díaz');
      expect(item.precio, 150000);
      expect(item.imagenUrl, 'https://cdn.test/1.jpg');
    });

    test('usa los nombres de campo en español como respaldo', () {
      final item = OrderItemModel.fromJson({
        'obra_id': 'obra-2',
        'obra_titulo': 'Tamo',
        'precio': '90000',
      });

      expect(item.obraId, 'obra-2');
      expect(item.obraTitulo, 'Tamo');
      expect(item.precio, 90000);
    });

    test('usa cadenas vacías y precio 0 cuando faltan las claves', () {
      final item = OrderItemModel.fromJson({});

      expect(item.obraId, '');
      expect(item.obraTitulo, '');
      expect(item.artistaNombre, '');
      expect(item.precio, 0);
      expect(item.imagenUrl, isNull);
    });

    test('precioFormateado formatea con separador de miles', () {
      const item = OrderItemModel(
        obraId: '1',
        obraTitulo: 'Obra',
        artistaNombre: 'Artista',
        precio: 1500000,
      );

      expect(item.precioFormateado, r'$1.500.000 COP');
    });
  });

  group('OrderModel.fromJson', () {
    Map<String, dynamic> baseJson() => {
          'id': 'order-1',
          'status': 'PENDIENTE',
          'total_amount': '250000',
          'created_at': '2025-03-01T12:00:00.000Z',
          'items': [
            {'artwork': 'obra-1', 'artwork_title': 'Obra 1', 'price': '100000'},
            {'artwork': 'obra-2', 'artwork_title': 'Obra 2', 'price': '150000'},
          ],
          'comprobante_pdf_url': 'https://cdn.test/comprobante.pdf',
          'wompi_payment_url': 'https://checkout.wompi.co/p/123',
        };

    test('mapea los campos básicos y los items anidados', () {
      final order = OrderModel.fromJson(baseJson());

      expect(order.id, 'order-1');
      expect(order.total, 250000);
      expect(order.creadoEn, DateTime.parse('2025-03-01T12:00:00.000Z'));
      expect(order.items, hasLength(2));
      expect(order.items.first.obraId, 'obra-1');
      expect(order.comprobantePdfUrl, 'https://cdn.test/comprobante.pdf');
      expect(order.wompiPaymentUrl, 'https://checkout.wompi.co/p/123');
    });

    test('usa order_id como respaldo cuando falta id', () {
      final json = {...baseJson()}..remove('id');
      final order = OrderModel.fromJson({...json, 'order_id': 'order-9'});

      expect(order.id, 'order-9');
    });

    test('normaliza los estados en mayúsculas del backend', () {
      expect(
        OrderModel.fromJson({...baseJson(), 'status': 'PAGADO'}).estado,
        'completado',
      );
      expect(
        OrderModel.fromJson({...baseJson(), 'status': 'CANCELADO'}).estado,
        'fallido',
      );
      expect(
        OrderModel.fromJson({...baseJson(), 'status': 'REEMBOLSADO'}).estado,
        'reembolsado',
      );
      expect(
        OrderModel.fromJson({...baseJson(), 'status': 'PENDIENTE'}).estado,
        'pendiente',
      );
      expect(
        OrderModel.fromJson({...baseJson(), 'status': 'algo_desconocido'})
            .estado,
        'pendiente',
      );
    });

    test('usa estado pendiente por defecto cuando no hay status ni estado',
        () {
      final json = {...baseJson()}..remove('status');

      expect(OrderModel.fromJson(json).estado, 'pendiente');
    });

    test('total es 0 cuando no hay total_amount ni total', () {
      final json = {...baseJson()}..remove('total_amount');

      expect(OrderModel.fromJson(json).total, 0);
    });

    test('items es una lista vacía cuando no vienen items', () {
      final json = {...baseJson()}..remove('items');

      expect(OrderModel.fromJson(json).items, isEmpty);
    });

    test('comprobantePdfUrl y wompiPaymentUrl son null cuando faltan', () {
      final json = {...baseJson()}
        ..remove('comprobante_pdf_url')
        ..remove('wompi_payment_url');

      final order = OrderModel.fromJson(json);

      expect(order.comprobantePdfUrl, isNull);
      expect(order.wompiPaymentUrl, isNull);
    });

    test('creadoEn cae a la fecha actual cuando created_at es inválido', () {
      final json = {...baseJson()}..remove('created_at');

      final before = DateTime.now();
      final order = OrderModel.fromJson(json);
      final after = DateTime.now();

      expect(
        order.creadoEn.isAfter(before.subtract(const Duration(seconds: 5))),
        isTrue,
      );
      expect(
        order.creadoEn.isBefore(after.add(const Duration(seconds: 5))),
        isTrue,
      );
    });
  });

  group('OrderModel getters de estado', () {
    OrderModel orderWithEstado(String estado) => OrderModel(
          id: '1',
          estado: estado,
          total: 0,
          creadoEn: DateTime(2025, 1, 1),
          items: const [],
        );

    test('cada getter es true solo para su estado correspondiente', () {
      expect(orderWithEstado('pendiente').isPendiente, isTrue);
      expect(orderWithEstado('completado').isPendiente, isFalse);

      expect(orderWithEstado('completado').isCompletado, isTrue);
      expect(orderWithEstado('pendiente').isCompletado, isFalse);

      expect(orderWithEstado('fallido').isFallido, isTrue);
      expect(orderWithEstado('pendiente').isFallido, isFalse);

      expect(orderWithEstado('reembolsado').isReembolsado, isTrue);
      expect(orderWithEstado('pendiente').isReembolsado, isFalse);
    });
  });

  group('OrderModel.totalFormateado', () {
    test('formatea el total con separador de miles y sufijo COP', () {
      final order = OrderModel(
        id: '1',
        estado: 'pendiente',
        total: 250000,
        creadoEn: DateTime(2025, 1, 1),
        items: const [],
      );

      expect(order.totalFormateado, r'$250.000 COP');
    });
  });
}
