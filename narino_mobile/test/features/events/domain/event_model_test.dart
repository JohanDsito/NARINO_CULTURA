import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';

void main() {
  group('EventModel.fromJson', () {
    Map<String, dynamic> baseJson() => {
          'id': 'evt-1',
          'title': 'Feria Artesanal',
          'event_type': 'FERIA',
          'start_date': '2020-01-01T10:00:00.000Z',
          'location': 'Plaza de Nariño',
          'description': 'Una feria de artesanos locales',
          'flyer_url': 'https://cdn.test/flyer.jpg',
          'featured_musicians': [
            {'nombre_artistico': 'Grupo Andino'},
            {'name': 'Los Pastusos'},
          ],
          'es_destacado': true,
          'esta_suscrito': true,
          'latitud': 1.2136,
          'longitud': -77.2811,
        };

    test('mapea los campos en inglés del backend a los del modelo', () {
      final event = EventModel.fromJson(baseJson());

      expect(event.id, 'evt-1');
      expect(event.nombre, 'Feria Artesanal');
      expect(event.tipo, 'feria');
      expect(event.fecha, DateTime.parse('2020-01-01T10:00:00.000Z'));
      expect(event.lugar, 'Plaza de Nariño');
      expect(event.descripcion, 'Una feria de artesanos locales');
      expect(event.flyerUrl, 'https://cdn.test/flyer.jpg');
      expect(event.artistasRelacionados, ['Grupo Andino', 'Los Pastusos']);
      expect(event.esDestacado, isTrue);
      expect(event.estaSuscrito, isTrue);
      expect(event.latitud, 1.2136);
      expect(event.longitud, -77.2811);
    });

    test('normaliza event_type a minúsculas', () {
      final event =
          EventModel.fromJson({...baseJson(), 'event_type': 'CONCIERTO'});

      expect(event.tipo, 'concierto');
    });

    test('usa "otro" como tipo cuando no viene event_type ni tipo', () {
      final json = {...baseJson()}..remove('event_type');

      final event = EventModel.fromJson(json);

      expect(event.tipo, 'otro');
    });

    test('esPasado es true cuando la fecha ya ocurrió', () {
      final event = EventModel.fromJson({
        ...baseJson(),
        'start_date': '2020-01-01T10:00:00.000Z',
      });

      expect(event.esPasado, isTrue);
    });

    test('esPasado es false cuando la fecha es futura', () {
      final futureDate =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      final event = EventModel.fromJson({
        ...baseJson(),
        'start_date': futureDate,
      });

      expect(event.esPasado, isFalse);
    });

    test('usa valores por defecto cuando faltan campos opcionales', () {
      final json = {
        'id': 'evt-2',
      };

      final event = EventModel.fromJson(json);

      expect(event.nombre, 'Sin título');
      expect(event.lugar, 'Sin lugar');
      expect(event.tipo, 'otro');
      expect(event.descripcion, isNull);
      expect(event.flyerUrl, isNull);
      expect(event.artistasRelacionados, isEmpty);
      expect(event.esDestacado, isFalse);
      expect(event.estaSuscrito, isFalse);
      expect(event.latitud, isNull);
      expect(event.longitud, isNull);
    });

    test('id es cadena vacía cuando el backend no envía id', () {
      final event = EventModel.fromJson({});

      expect(event.id, '');
    });

    test('acepta latitude/longitude en inglés como fallback', () {
      final json = {...baseJson()}
        ..remove('latitud')
        ..remove('longitud');
      json['latitude'] = 4.5;
      json['longitude'] = -75.6;

      final event = EventModel.fromJson(json);

      expect(event.latitud, 4.5);
      expect(event.longitud, -75.6);
    });

    test('acepta image_url y flyer como fallback de flyer_url', () {
      final soloImageUrl = {...baseJson()}..remove('flyer_url');
      soloImageUrl['image_url'] = 'https://cdn.test/image.jpg';
      expect(EventModel.fromJson(soloImageUrl).flyerUrl,
          'https://cdn.test/image.jpg');

      final soloFlyer = {...baseJson()}..remove('flyer_url');
      soloFlyer['flyer'] = 'https://cdn.test/legacy.jpg';
      expect(EventModel.fromJson(soloFlyer).flyerUrl,
          'https://cdn.test/legacy.jpg');
    });

    test('mapea artistas cuando vienen como lista de strings', () {
      final json = {
        ...baseJson(),
        'featured_musicians': ['Ana', 'Luis'],
      };

      final event = EventModel.fromJson(json);

      expect(event.artistasRelacionados, ['Ana', 'Luis']);
    });

    test('usa el id del artista cuando no viene nombre', () {
      final json = {
        ...baseJson(),
        'featured_musicians': [
          {'id': 'artist-99'},
        ],
      };

      final event = EventModel.fromJson(json);

      expect(event.artistasRelacionados, ['artist-99']);
    });

    test('is_featured e is_subscribed son fallback de los campos en español',
        () {
      final json = {...baseJson()}
        ..remove('es_destacado')
        ..remove('esta_suscrito');
      json['is_featured'] = true;
      json['is_subscribed'] = true;

      final event = EventModel.fromJson(json);

      expect(event.esDestacado, isTrue);
      expect(event.estaSuscrito, isTrue);
    });
  });

  group('EventModel.tipoLabel', () {
    test('devuelve la etiqueta correspondiente al tipo', () {
      final event = EventModel(
        id: '1',
        nombre: '',
        tipo: 'concierto',
        fecha: DateTime(2025, 1, 1),
        lugar: '',
        artistasRelacionados: const [],
        esDestacado: false,
        esPasado: false,
        estaSuscrito: false,
      );

      expect(event.tipoLabel, '🎵 Concierto');
    });

    test('devuelve la etiqueta genérica para un tipo desconocido', () {
      final event = EventModel(
        id: '1',
        nombre: '',
        tipo: 'desconocido',
        fecha: DateTime(2025, 1, 1),
        lugar: '',
        artistasRelacionados: const [],
        esDestacado: false,
        esPasado: false,
        estaSuscrito: false,
      );

      expect(event.tipoLabel, '📅 Evento');
    });
  });

  group('EventModel.fechaFormateada', () {
    test('formatea día, mes abreviado y hora', () {
      final event = EventModel(
        id: '1',
        nombre: '',
        tipo: 'otro',
        fecha: DateTime(2025, 3, 5, 9, 5),
        lugar: '',
        artistasRelacionados: const [],
        esDestacado: false,
        esPasado: false,
        estaSuscrito: false,
      );

      expect(event.fechaFormateada, '5 Mar · 09:05');
    });
  });
}
