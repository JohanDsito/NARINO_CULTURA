// TEMPORAL / herramienta de diseño: capturas del módulo de Eventos.
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/events/data/events_repository.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';
import 'package:narino_cultura/features/events/presentation/providers/events_provider.dart';
import 'package:narino_cultura/features/events/presentation/screens/event_detail_screen.dart';
import 'package:narino_cultura/features/events/presentation/screens/events_screen.dart';
import 'package:narino_cultura/features/events/presentation/screens/publish_event_screen.dart';

import 'preview_support.dart';

final _hoy = DateTime.now();

EventModel _e(String id, String nombre, String tipo, int dias, int hora,
        {bool publicado = true, String? desc}) =>
    EventModel(
      id: id,
      nombre: nombre,
      tipo: tipo,
      fecha: DateTime(_hoy.year, _hoy.month, _hoy.day + dias, hora),
      fechaFin: DateTime(_hoy.year, _hoy.month, _hoy.day + dias, hora + 2),
      lugar: 'Teatro Imperial, Pasto',
      descripcion: desc,
      artistasRelacionados: const [],
      esDestacado: id == '1',
      esPasado: false,
      estaSuscrito: false,
      publicado: publicado,
    );

final _eventos = [
  _e('1', 'Tributo a Gustavo Cerati - Rock en Español', 'concierto', 0, 19,
      desc: 'Ensambles locales rinden homenaje a Cerati con un recorrido por '
          'Soda Stereo y su etapa solista. Entrada libre hasta completar aforo.'),
  _e('2', 'Feria Artesanal del Barniz de Pasto', 'feria', 2, 10),
  _e('3', 'Taller: tejido en guanga', 'taller', 4, 15),
  _e('4', 'Muestra: Archivo Fotográfico del 6 de enero', 'exposicion', 12, 18,
      publicado: false),
];

class _Repo extends EventsRepository {
  @override
  Future<List<EventModel>> getEvents(
          {String? tipo, bool mostrarPasados = false}) async =>
      tipo == null ? _eventos : _eventos.where((e) => e.tipo == tipo).toList();
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    final ov = [
      eventsRepositoryProvider.overrideWithValue(_Repo()),
      eventDetailProvider.overrideWith((ref, id) async => _eventos.first),
      currentUserRoleProvider.overrideWith((ref) async => 'artista'),
    ];
    testWidgets('eventos', skip: previewSkip, (t) async {
      await capture(t, name: 'eventos', dark: dark, overrides: ov, height: 1350,
          home: const MainShell(location: '/events', child: EventsScreen()));
    });
    testWidgets('eventos_lista', skip: previewSkip, (t) async {
      await capture(t, name: 'eventos_lista', dark: dark, overrides: ov, height: 1100,
          home: const EventsScreen(), interact: (t) async {
        await t.tap(find.byTooltip('Ver como lista'));
      });
    });
    testWidgets('evento_detalle', skip: previewSkip, (t) async {
      await capture(t, name: 'evento_detalle', dark: dark, overrides: ov, height: 1100,
          home: const EventDetailScreen(eventId: '1'));
    });
    testWidgets('evento_publicar', skip: previewSkip, (t) async {
      await capture(t, name: 'evento_publicar', dark: dark, overrides: ov, height: 1500,
          home: const PublishEventScreen());
    });
  }
}
