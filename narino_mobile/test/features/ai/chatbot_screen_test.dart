import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/theme/app_theme.dart';
import 'package:narino_cultura/features/ai/data/ai_service.dart';
import 'package:narino_cultura/features/ai/presentation/screens/chatbot_screen.dart';

class _FakeAi extends AiService {
  final historiales = <List<Map<String, String>>>[];
  Object? error;

  @override
  Future<String> chat({
    required String mensaje,
    List<Map<String, String>> history = const [],
  }) async {
    historiales.add(List.of(history));
    if (error != null) throw error!;
    return 'El **Carnaval** se celebra en enero.\n* Día de Negros\n* Día de Blancos';
  }
}

Widget _app(AiService ai) => MaterialApp(
      theme: AppTheme.light,
      home: ChatbotScreen(service: ai),
    );

void main() {
  testWidgets('envía, muestra la respuesta sin asteriscos y guarda el turno como model',
      (tester) async {
    final ai = _FakeAi();
    await tester.pumpWidget(_app(ai));

    await tester.enterText(find.byType(TextField), 'Háblame del Carnaval');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Háblame del Carnaval'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('Día de Negros', findRichText: true), findsOneWidget);

    // Segunda pregunta: el historial lleva el turno del bot como 'model'.
    await tester.enterText(find.byType(TextField), '¿Y la música?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(ai.historiales.last.map((h) => h['role']), ['user', 'model']);
  });

  testWidgets('muestra el error con opción de reintentar', (tester) async {
    final ai = _FakeAi()
      ..error = const FormatException('Vas muy rápido. Espera un momento.');
    await tester.pumpWidget(_app(ai));

    await tester.enterText(find.byType(TextField), 'Hola');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Vas muy rápido. Espera un momento.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    ai.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Reintentar'), findsNothing);
  });
}
