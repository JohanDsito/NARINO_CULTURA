import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/notifications/domain/notification_model.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('mapea los campos cuando vienen en español', () {
      final n = NotificationModel.fromJson({
        'id': 5,
        'tipo': 'obra_vendida',
        'titulo': 'Tu obra se vendió',
        'descripcion': 'Detalles de la venta',
        'creado_en': '2025-06-01T10:00:00.000Z',
        'leida': true,
        'referencia_id': 42,
      });

      expect(n.id, 5);
      expect(n.tipo, 'obra_vendida');
      expect(n.titulo, 'Tu obra se vendió');
      expect(n.descripcion, 'Detalles de la venta');
      expect(n.creadoEn, DateTime.parse('2025-06-01T10:00:00.000Z'));
      expect(n.leida, isTrue);
      expect(n.referenciaId, 42);
    });

    test('usa los alias en inglés cuando faltan los campos en español', () {
      final n = NotificationModel.fromJson({
        'id': '7',
        'type': 'auction_won',
        'title': 'Ganaste la subasta',
        'body': 'Detalles',
        'created_at': '2025-07-01T00:00:00.000Z',
        'read': true,
        'objeto_id': '99',
      });

      expect(n.id, 7);
      expect(n.tipo, 'auction_won');
      expect(n.titulo, 'Ganaste la subasta');
      expect(n.descripcion, 'Detalles');
      expect(n.creadoEn, DateTime.parse('2025-07-01T00:00:00.000Z'));
      expect(n.leida, isTrue);
      expect(n.referenciaId, 99);
    });

    test('usa "message" como descripción cuando no hay body ni descripcion',
        () {
      final n = NotificationModel.fromJson({'id': 1, 'message': 'Hola'});

      expect(n.descripcion, 'Hola');
    });

    test('usa valores por defecto cuando no vienen los campos', () {
      final n = NotificationModel.fromJson(const {});

      expect(n.id, 0);
      expect(n.tipo, '');
      expect(n.titulo, 'Notificación');
      expect(n.descripcion, '');
      expect(n.leida, isFalse);
      expect(n.referenciaId, isNull);
    });

    test('leida es false si el valor no es exactamente el booleano true', () {
      final n = NotificationModel.fromJson({'id': 1, 'leida': 'true'});

      expect(n.leida, isFalse);
    });

    test(
        'usa la fecha actual cuando no hay ningún campo de fecha reconocible',
        () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));

      final n = NotificationModel.fromJson({'id': 1});

      final after = DateTime.now().add(const Duration(seconds: 2));
      expect(n.creadoEn.isAfter(before), isTrue);
      expect(n.creadoEn.isBefore(after), isTrue);
    });

    test('reconoce los alias de fecha "fecha" y "timestamp"', () {
      final n1 =
          NotificationModel.fromJson({'fecha': '2025-01-01T00:00:00.000Z'});
      final n2 = NotificationModel.fromJson(
          {'timestamp': '2025-02-01T00:00:00.000Z'});

      expect(n1.creadoEn, DateTime.parse('2025-01-01T00:00:00.000Z'));
      expect(n2.creadoEn, DateTime.parse('2025-02-01T00:00:00.000Z'));
    });

    test(
        'deriva referenciaId desde el payload en "data" cuando no viene directo',
        () {
      final n = NotificationModel.fromJson({
        'id': 1,
        'data': {'obra_id': 15},
      });

      expect(n.referenciaId, 15);
    });

    test(
        'deriva referenciaId desde el payload en "payload" cuando no viene directo',
        () {
      final n = NotificationModel.fromJson({
        'id': 1,
        'payload': {'auction_id': 21},
      });

      expect(n.referenciaId, 21);
    });

    test('prefiere referencia_id explícito sobre el id dentro del payload',
        () {
      final n = NotificationModel.fromJson({
        'id': 1,
        'referencia_id': 3,
        'data': {'obra_id': 999},
      });

      expect(n.referenciaId, 3);
    });

    test('referenciaId es null cuando no puede derivarse de ningún campo',
        () {
      final n = NotificationModel.fromJson({
        'id': 1,
        'data': {'foo': 'bar'},
      });

      expect(n.referenciaId, isNull);
    });
  });
}
