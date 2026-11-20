// TEMPORAL / herramienta de diseño: capturas de la bandeja de notificaciones.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/notifications/data/notifications_service.dart';
import 'package:narino_cultura/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:narino_cultura/features/notifications/presentation/screens/notifications_screen.dart';

import 'preview_support.dart';

class _Svc extends NotificationsService {
  @override
  Future<List<dynamic>> list({bool? onlyUnread}) async {
    final now = DateTime.now();
    String hace(Duration d) => now.subtract(d).toIso8601String();
    return [
      {'id': '1', 'type': 'AUCTION_BID', 'title': 'Te superaron en una puja',
       'body': 'Alguien ofreció \$420.000 por "Cóndor Andino". ¡Aún estás a tiempo!',
       'data': {'auction_id': 'a1'}, 'read': false, 'created_at': hace(const Duration(minutes: 12))},
      {'id': '2', 'type': 'EVENT_REGISTRATION', 'title': 'Inscripción confirmada',
       'body': 'Te esperamos en "Taller de barniz de Pasto" el sábado a las 10:00.',
       'data': {'event_id': 'e1'}, 'read': false, 'created_at': hace(const Duration(hours: 3))},
      {'id': '3', 'type': 'PAYMENT_WEBHOOK', 'title': 'Pago aprobado',
       'body': 'Tu compra de "Tejido Guaneña" quedó pagada.',
       'data': {'order_id': 'o1'}, 'read': true, 'created_at': hace(const Duration(days: 2))},
      {'id': '4', 'type': 'AUCTION_CLOSED', 'title': '¡Ganaste la subasta!',
       'body': 'Tienes 48 horas para pagar "Volcán Galeras".',
       'data': {'auction_id': 'a2'}, 'read': true, 'created_at': hace(const Duration(days: 4))},
      {'id': '5', 'type': 'EVENT_PUBLISHED', 'title': 'Nuevo evento: Carnaval de Negros y Blancos',
       'body': 'Desfile magno, 6 de enero en Pasto.',
       'data': {'event_id': 'e2'}, 'read': true, 'created_at': hace(const Duration(days: 12))},
    ];
  }

  @override
  Future<int> unreadCount() async => 2;
}

void main() {
  setUpAll(loadPreviewFonts);
  for (final dark in [true, false]) {
    testWidgets('notificaciones', skip: previewSkip, (t) async {
      await capture(t,
          name: 'notificaciones',
          dark: dark,
          overrides: <Override>[
            notificationsServiceProvider.overrideWithValue(_Svc()),
          ],
          height: 900,
          home: const NotificationsScreen());
    });
  }
}
