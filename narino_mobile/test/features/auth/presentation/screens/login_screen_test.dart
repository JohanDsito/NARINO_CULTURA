import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/session_expiry.dart';
import 'package:narino_cultura/features/auth/presentation/screens/login_screen.dart';

import '../../../../support/test_helpers.dart';

void main() {
  setUpAll(ensureApiClientInitialized);

  // MO-WT-01
  testWidgets('LoginScreen renderiza con correo y contraseña',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });

  // MO-SEG-04: al llegar por sesión expirada se explica por qué.
  testWidgets('muestra "Tu sesión expiró" solo si la sesión expiró',
      (WidgetTester tester) async {
    SessionExpiry.expire();
    await tester.pumpWidget(wrap(const LoginScreen()));
    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);

    // Volver al login después (p. ej. tras cerrar sesión) ya no lo muestra.
    await tester.pumpWidget(wrap(const LoginScreen(key: ValueKey('otra'))));
    expect(find.textContaining('Tu sesión expiró'), findsNothing);
  });
}
