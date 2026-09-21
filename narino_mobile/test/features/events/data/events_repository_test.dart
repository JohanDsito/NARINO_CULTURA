import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/events/data/events_repository.dart';
import 'package:narino_cultura/features/events/data/events_service.dart';

class _MockEventsService extends Mock implements EventsService {}

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

DioException _timeoutError() => DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionTimeout,
    );

Map<String, dynamic> _eventJson({String id = '1'}) => {
      'id': id,
      'title': 'Evento $id',
      'event_type': 'FERIA',
      'start_date': '2025-01-01T00:00:00.000Z',
      'location': 'Pasto',
      'featured_musicians': const [],
    };

void main() {
  late _MockEventsService service;
  late EventsRepository repo;

  setUp(() {
    service = _MockEventsService();
    repo = EventsRepository(service: service);
  });

  group('getEvents', () {
    test('mapea la lista de eventos desde el servicio', () async {
      when(() => service.getEvents(
            tipo: any(named: 'tipo'),
            mostrarPasados: any(named: 'mostrarPasados'),
          )).thenAnswer(
              (_) async => [_eventJson(id: '1'), _eventJson(id: '2')]);

      final result = await repo.getEvents();

      expect(result, hasLength(2));
      expect(result.first.id, '1');
      expect(result.first.nombre, 'Evento 1');
    });

    test('traduce un error de conexión por timeout a un mensaje entendible',
        () async {
      when(() => service.getEvents(
            tipo: any(named: 'tipo'),
            mostrarPasados: any(named: 'mostrarPasados'),
          )).thenThrow(_timeoutError());

      await expectLater(
        repo.getEvents(),
        throwsA('Sin conexión al servidor.'),
      );
    });

    test('traduce un error inesperado a un mensaje genérico', () async {
      when(() => service.getEvents(
            tipo: any(named: 'tipo'),
            mostrarPasados: any(named: 'mostrarPasados'),
          )).thenThrow(_httpError(500));

      await expectLater(
        repo.getEvents(),
        throwsA('Ocurrió un error inesperado.'),
      );
    });
  });

  group('getEventDetail', () {
    test('mapea el detalle del evento', () async {
      when(() => service.getEventDetail('1'))
          .thenAnswer((_) async => _eventJson(id: '1'));

      final result = await repo.getEventDetail('1');

      expect(result.id, '1');
      expect(result.lugar, 'Pasto');
    });

    test('extrae el detail de un error 400', () async {
      when(() => service.getEventDetail('1')).thenThrow(_httpError(400, data: {
            'detail': 'Evento no encontrado.',
          }));

      await expectLater(
        repo.getEventDetail('1'),
        throwsA('Evento no encontrado.'),
      );
    });
  });

  group('registerToEvent', () {
    test('llama al servicio sin lanzar error en caso de éxito', () async {
      when(() => service.registerToEvent('1')).thenAnswer((_) async {});

      await repo.registerToEvent('1');

      verify(() => service.registerToEvent('1')).called(1);
    });

    test('traduce un 403 a un mensaje entendible', () async {
      when(() => service.registerToEvent('1')).thenThrow(_httpError(403));

      await expectLater(
        repo.registerToEvent('1'),
        throwsA('Solo gestores culturales pueden publicar eventos.'),
      );
    });
  });

  group('unregisterFromEvent', () {
    test('llama al servicio sin lanzar error en caso de éxito', () async {
      when(() => service.unregisterFromEvent('1')).thenAnswer((_) async {});

      await repo.unregisterFromEvent('1');

      verify(() => service.unregisterFromEvent('1')).called(1);
    });

    test('traduce un error inesperado a un mensaje genérico', () async {
      when(() => service.unregisterFromEvent('1')).thenThrow(_httpError(404));

      await expectLater(
        repo.unregisterFromEvent('1'),
        throwsA('Ocurrió un error inesperado.'),
      );
    });
  });

  group('publishEvent', () {
    test('reenvía imageUrl al servicio cuando se proporciona', () async {
      when(() => service.publishEvent(
            nombre: any(named: 'nombre'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
            lugar: any(named: 'lugar'),
            descripcion: any(named: 'descripcion'),
            imageUrl: any(named: 'imageUrl'),
            artistasRelacionados: any(named: 'artistasRelacionados'),
            isPublished: any(named: 'isPublished'),
          )).thenAnswer((_) async => _eventJson(id: '1'));

      await repo.publishEvent(
        nombre: 'Feria',
        tipo: 'feria',
        fecha: '2025-01-01T00:00:00.000Z',
        lugar: 'Pasto',
        imageUrl: 'https://cdn.test/flyer.jpg',
      );

      verify(() => service.publishEvent(
            nombre: 'Feria',
            tipo: 'feria',
            fecha: '2025-01-01T00:00:00.000Z',
            lugar: 'Pasto',
            descripcion: null,
            imageUrl: 'https://cdn.test/flyer.jpg',
            artistasRelacionados: null,
            isPublished: false,
          )).called(1);
    });

    test('reenvía imageUrl como null cuando no se proporciona', () async {
      when(() => service.publishEvent(
            nombre: any(named: 'nombre'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
            lugar: any(named: 'lugar'),
            descripcion: any(named: 'descripcion'),
            imageUrl: any(named: 'imageUrl'),
            artistasRelacionados: any(named: 'artistasRelacionados'),
            isPublished: any(named: 'isPublished'),
          )).thenAnswer((_) async => _eventJson(id: '1'));

      await repo.publishEvent(
        nombre: 'Feria',
        tipo: 'feria',
        fecha: '2025-01-01T00:00:00.000Z',
        lugar: 'Pasto',
      );

      verify(() => service.publishEvent(
            nombre: 'Feria',
            tipo: 'feria',
            fecha: '2025-01-01T00:00:00.000Z',
            lugar: 'Pasto',
            descripcion: null,
            imageUrl: null,
            artistasRelacionados: null,
            isPublished: false,
          )).called(1);
    });

    test('mapea el evento publicado desde la respuesta del servicio',
        () async {
      when(() => service.publishEvent(
            nombre: any(named: 'nombre'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
            lugar: any(named: 'lugar'),
            descripcion: any(named: 'descripcion'),
            imageUrl: any(named: 'imageUrl'),
            artistasRelacionados: any(named: 'artistasRelacionados'),
            isPublished: any(named: 'isPublished'),
          )).thenAnswer((_) async => _eventJson(id: '42'));

      final result = await repo.publishEvent(
        nombre: 'Feria',
        tipo: 'feria',
        fecha: '2025-01-01T00:00:00.000Z',
        lugar: 'Pasto',
      );

      expect(result.id, '42');
    });

    test('traduce un 403 a un mensaje entendible cuando el usuario no puede publicar',
        () async {
      when(() => service.publishEvent(
            nombre: any(named: 'nombre'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
            lugar: any(named: 'lugar'),
            descripcion: any(named: 'descripcion'),
            imageUrl: any(named: 'imageUrl'),
            artistasRelacionados: any(named: 'artistasRelacionados'),
            isPublished: any(named: 'isPublished'),
          )).thenThrow(_httpError(403));

      await expectLater(
        repo.publishEvent(
          nombre: 'Feria',
          tipo: 'feria',
          fecha: '2025-01-01T00:00:00.000Z',
          lugar: 'Pasto',
        ),
        throwsA('Solo gestores culturales pueden publicar eventos.'),
      );
    });

    test('extrae el detail de un error 400 al publicar', () async {
      when(() => service.publishEvent(
            nombre: any(named: 'nombre'),
            tipo: any(named: 'tipo'),
            fecha: any(named: 'fecha'),
            lugar: any(named: 'lugar'),
            descripcion: any(named: 'descripcion'),
            imageUrl: any(named: 'imageUrl'),
            artistasRelacionados: any(named: 'artistasRelacionados'),
            isPublished: any(named: 'isPublished'),
          )).thenThrow(_httpError(400, data: {
            'detail': 'La fecha debe ser futura.',
          }));

      await expectLater(
        repo.publishEvent(
          nombre: 'Feria',
          tipo: 'feria',
          fecha: '2025-01-01T00:00:00.000Z',
          lugar: 'Pasto',
        ),
        throwsA('La fecha debe ser futura.'),
      );
    });
  });
}
