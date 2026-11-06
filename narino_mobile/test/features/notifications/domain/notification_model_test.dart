import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/notifications/domain/notification_model.dart';

void main() {
  const uuid = '3f2c1a9e-8b7d-4c6e-9f10-2a3b4c5d6e7f';
  const auctionId = 'a1b2c3d4-0000-4000-8000-000000000001';

  group('NotificationModel.fromJson', () {
    test('mapea el contrato del backend (HU-B09)', () {
      final n = NotificationModel.fromJson({
        'id': uuid,
        'type': 'AUCTION_BID',
        'title': 'Nueva puja en tu subasta',
        'body': 'Ofrecieron \$ 120.000 por «Luna».',
        'data': {'auction_id': auctionId, 'url': '/auctions/$auctionId'},
        'read': false,
        'read_at': null,
        'created_at': '2026-06-01T10:00:00Z',
      });

      expect(n.id, uuid);
      expect(n.tipo, 'AUCTION_BID');
      expect(n.titulo, 'Nueva puja en tu subasta');
      expect(n.descripcion, contains('Luna'));
      expect(n.leida, isFalse);
      expect(n.creadoEn.toUtc(), DateTime.parse('2026-06-01T10:00:00Z'));
      expect(n.referenciaId, auctionId);
      expect(n.ruta, '/auctions/$auctionId');
    });

    test('considera leída una notificación con read_at', () {
      final n = NotificationModel.fromJson({
        'id': uuid,
        'read_at': '2026-06-01T10:00:00Z',
      });

      expect(n.leida, isTrue);
    });

    test('mantiene compatibilidad con los campos en español', () {
      final n = NotificationModel.fromJson({
        'id': uuid,
        'tipo': 'obra_vendida',
        'titulo': 'Tu obra se vendió',
        'descripcion': 'Detalles',
        'creado_en': '2025-06-01T10:00:00.000Z',
        'leida': true,
      });

      expect(n.tipo, 'obra_vendida');
      expect(n.titulo, 'Tu obra se vendió');
      expect(n.descripcion, 'Detalles');
      expect(n.leida, isTrue);
    });

    test('usa valores por defecto cuando no vienen los campos', () {
      final n = NotificationModel.fromJson(const {});

      expect(n.id, '');
      expect(n.tipo, '');
      expect(n.titulo, 'Notificación');
      expect(n.descripcion, '');
      expect(n.leida, isFalse);
      expect(n.referenciaId, isNull);
      expect(n.ruta, isNull);
    });
  });

  group('NotificationModel.ruta', () {
    NotificationModel withData(Map<String, dynamic> data) =>
        NotificationModel.fromJson({'id': uuid, 'data': data});

    test('prioriza la subasta sobre la orden (ganador de subasta)', () {
      final n = withData({'auction_id': auctionId, 'order_id': 'o-1'});
      expect(n.ruta, '/auctions/$auctionId');
    });

    test('lleva al evento', () {
      expect(withData({'event_id': 'e-1'}).ruta, '/events/e-1');
    });

    test('lleva al detalle de la orden', () {
      expect(withData({'order_id': 'o-1'}).ruta, '/marketplace/order/o-1');
    });

    test('ignora ids vacíos o nulos', () {
      expect(withData({'auction_id': null, 'event_id': ''}).ruta, isNull);
    });
  });

  test('copyWith solo cambia el estado de lectura', () {
    final n = NotificationModel.fromJson({
      'id': uuid,
      'title': 'Hola',
      'data': {'event_id': 'e-1'},
    });
    final read = n.copyWith(leida: true);

    expect(read.leida, isTrue);
    expect(read.id, n.id);
    expect(read.titulo, n.titulo);
    expect(read.ruta, n.ruta);
  });
}
