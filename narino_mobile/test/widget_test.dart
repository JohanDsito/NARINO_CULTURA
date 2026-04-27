// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/features/auth/presentation/screens/login_screen.dart';
import 'package:narino_cultura/features/auth/presentation/providers/auth_guard_provider.dart';

void main() {
  testWidgets('App boots to login', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) async => false),
        ],
        child: const NarinoCulturaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
