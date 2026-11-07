// TEMPORAL / herramienta de diseño: capturas del asistente cultural.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/ai/data/ai_service.dart';
import 'package:narino_cultura/features/ai/presentation/screens/chatbot_screen.dart';

import 'preview_support.dart';

class _Ai extends AiService {
  @override
  Future<String> chat({
    required String mensaje,
    List<Map<String, String>> history = const [],
  }) async =>
      'El **Carnaval de Negros y Blancos** se celebra del 2 al 7 de enero en '
      'Pasto y es Patrimonio Inmaterial de la Humanidad.\n\n'
      'Sus días principales:\n'
      '* **Día de Negros** (5 de enero): todos se pintan de negro.\n'
      '* **Día de Blancos** (6 de enero): talco y el Desfile Magno.\n\n'
      '¿Quieres que te recomiende artistas que trabajan las carrozas?';
}

void main() {
  setUpAll(loadPreviewFonts);
  for (final dark in [true, false]) {
    testWidgets('chat_vacio', skip: previewSkip, (t) async {
      await capture(t,
          name: 'chat_vacio', dark: dark, height: 844, home: ChatbotScreen(service: _Ai()));
    });
    testWidgets('chat_conversacion', skip: previewSkip, (t) async {
      await capture(t,
          name: 'chat_conversacion',
          dark: dark,
          height: 844,
          home: ChatbotScreen(service: _Ai()),
          interact: (t) async {
            await t.tap(find.text('El Carnaval'));
            await t.pump(const Duration(milliseconds: 600));
            await t.enterText(find.byType(TextField), '¿Y qué música suena en el desfile?');
          });
    });
  }
}
