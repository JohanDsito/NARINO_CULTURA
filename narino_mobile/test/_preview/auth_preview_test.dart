// TEMPORAL / herramienta de diseño: capturas de las pantallas de acceso.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:narino_cultura/features/auth/presentation/screens/login_screen.dart';
import 'package:narino_cultura/features/auth/presentation/screens/register_screen.dart';
import 'package:narino_cultura/features/auth/presentation/screens/verify_email_pending_screen.dart';

import 'preview_support.dart';

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    testWidgets('login', skip: previewSkip, (t) async {
      await capture(t, name: 'login', dark: dark, home: const LoginScreen());
    });
    testWidgets('registro', skip: previewSkip, (t) async {
      await capture(t,
          name: 'registro',
          dark: dark,
          height: 1560,
          home: const RegisterScreen(), interact: (t) async {
        await t.tap(find.text('Descubrir y comprar'));
        await t.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'Carnaval1');
      });
    });
    testWidgets('recuperar', skip: previewSkip, (t) async {
      await capture(t,
          name: 'recuperar', dark: dark, home: const ForgotPasswordScreen());
    });
    testWidgets('verificar', skip: previewSkip, (t) async {
      await capture(t,
          name: 'verificar',
          dark: dark,
          height: 1100,
          home: const VerifyEmailPendingScreen(email: 'valeria@correo.com'));
    });
  }
}
