// TEMPORAL / herramienta de diseño: utilidades para generar capturas PNG de
// pantallas con la fuente real (Inter). Las pruebas que la usan se saltan si
// no se pasa --dart-define=OUT=<carpeta>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/theme/app_theme.dart';

import '../support/test_helpers.dart';

const previewOut = String.fromEnvironment('OUT');
const _fonts = String.fromEnvironment('FONTS');
const _icons = String.fromEnvironment('ICONS');
// Pruebas de estrés: ancho del teléfono y escala de texto (p. ej. 320 y 1.3).
const _width = int.fromEnvironment('WIDTH', defaultValue: 390);
const _textScale = String.fromEnvironment('TEXTSCALE', defaultValue: '1.0');
bool get previewSkip => previewOut.isEmpty;

Future<void> _load(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> loadPreviewFonts() async {
  if (previewSkip) return;
  ensureApiClientInitialized();
  const weights = {
    '300': 'Inter_300',
    '400': 'Inter_regular',
    '500': 'Inter_500',
    '600': 'Inter_600',
    '700': 'Inter_700',
    '800': 'Inter_800',
  };
  for (final e in weights.entries) {
    await _load(e.value, '$_fonts/Inter-${e.key}.ttf');
  }
  await _load('Inter_300italic', '$_fonts/Inter-300.ttf');
  await _load('MaterialIcons', _icons);
}

/// Monta [home] con el tema indicado y guarda `<name>_<modo>.png`.
Future<void> capture(
  WidgetTester tester, {
  required String name,
  required bool dark,
  required Widget home,
  List<Override> overrides = const [],
  double height = 844,
  Future<void> Function(WidgetTester)? interact,
}) async {
  tester.view.physicalSize = Size(_width * 2.0, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: home,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(double.parse(_textScale))),
            child: child!,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (interact != null) {
    await interact(tester);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  await tester.runAsync(() async {
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await ro.toImage(pixelRatio: 1.5);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$previewOut/${name}_${dark ? 'oscuro' : 'claro'}.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
  });
}
