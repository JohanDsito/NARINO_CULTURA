import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:narino_cultura/core/theme/app_theme.dart';
import 'package:narino_cultura/features/events/presentation/screens/event_notification_preferences_screen.dart';
import 'package:narino_cultura/features/notifications/data/notifications_service.dart';

/// Backend sin `event-preferences/`: GET y PATCH responden 404.
class _Sin404 extends NotificationsService {
  DioException _e() => DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 404),
      );

  @override
  Future<Map<String, dynamic>> getEventPreferences() async => throw _e();

  @override
  Future<void> saveEventPreferences(Map<String, dynamic> data) async => throw _e();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('sin endpoint guarda en el teléfono, avisa y cierra (antes daba error)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (c, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => c.push('/prefs'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/prefs',
          builder: (_, __) =>
              EventNotificationPreferencesScreen(service: _Sin404()),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Avisos de eventos'), findsOneWidget);
    await tester.tap(find.text('Concierto'));
    await tester.pump();
    await tester.tap(find.text('Guardar avisos'));
    await tester.pumpAndSettle();

    expect(find.text('Guardamos tus avisos en este teléfono'), findsOneWidget);
    expect(find.text('Avisos de eventos'), findsNothing);
  });
}
