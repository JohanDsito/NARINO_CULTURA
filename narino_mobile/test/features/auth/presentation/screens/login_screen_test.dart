import 'package:flutter_test/flutter_test.dart';
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
}
