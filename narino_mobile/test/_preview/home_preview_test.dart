// TEMPORAL: genera capturas PNG de Inicio para revisar el diseño. Se borra
// después de usarlo. Ejecutar con:
//   flutter test test/_preview/home_preview_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/core/theme/app_theme.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';
import 'package:narino_cultura/features/home/presentation/screens/home_screen.dart';
import 'package:narino_cultura/features/notifications/presentation/providers/notifications_provider.dart';

import '../support/test_helpers.dart';

const _out = String.fromEnvironment('OUT');
const _fonts = String.fromEnvironment('FONTS');
const _icons = String.fromEnvironment('ICONS');

Future<void> _load(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    if (_out.isEmpty) return;
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
  });

  final now = DateTime.now();
  EventModel ev(String id, String nombre, int dias, int hora, String desc) =>
      EventModel(
        id: id,
        nombre: nombre,
        tipo: 'concierto',
        fecha: DateTime(now.year, now.month, now.day + dias, hora),
        lugar: 'Teatro Imperial, Pasto',
        descripcion: desc,
        artistasRelacionados: const [],
        esDestacado: false,
        esPasado: false,
        estaSuscrito: false,
      );

  final events = [
    ev('1', 'Tributo a Gustavo Cerati - Rock en Español', 0, 19,
        'Ensambles locales rinden homenaje en el Teatro Imperial.'),
    ev('2', 'Subasta: Archivo Fotográfico 2026', 3, 14,
        'Puja en vivo por los mejores encuadres del 6 de enero.'),
    ev('3', 'Taller: Barniz de Pasto', 5, 10,
        'Aprende la técnica milenaria con artesanos locales.'),
  ];
  final artworks = [
    testArtwork(id: 'a', titulo: 'Cóndor Andino', artistaNombre: 'María Torres', precio: 320000),
    testArtwork(id: 'b', titulo: 'Volcán en Calma', artistaNombre: 'Luis Zambrano', precio: 180000),
    testArtwork(id: 'c', titulo: 'Carnaval Eterno', artistaNombre: 'Ana Benavides', precio: 540000),
  ];

  for (final dark in [true, false]) {
    testWidgets('captura Inicio ${dark ? 'oscuro' : 'claro'}', skip: _out.isEmpty,
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 2700 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 3),
            homeFeaturedArtworksProvider.overrideWith((ref, l) async => artworks),
            homeUpcomingEventsProvider.overrideWith((ref, l) async => events),
            homeAiArtworkRecommendationsProvider
                .overrideWith((ref, l) async => const <ArtworkModel>[]),
            currentUserRoleProvider.overrideWith((ref) async => 'COMPRADOR'),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: const MainShell(location: '/home', child: HomeScreen()),
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.runAsync(() async {
        final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await ro.toImage(pixelRatio: 1.5);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/inicio_${dark ? 'oscuro' : 'claro'}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }
}
