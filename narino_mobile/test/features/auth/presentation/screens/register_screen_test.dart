import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/auth/presentation/screens/register_screen.dart';

import '../../../../support/test_helpers.dart';

void main() {
  setUpAll(ensureApiClientInitialized);

  // MO-WT-02
  // El registro público siempre crea una cuenta de artista (role: 'ARTISTA'
  // fijo en register_screen.dart); no ofrece selector de rol. Cuentas de
  // comprador/gestor cultural se crean por otra vía.
  testWidgets('RegisterScreen renderiza el formulario de registro',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const RegisterScreen()));

    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
  });
}
