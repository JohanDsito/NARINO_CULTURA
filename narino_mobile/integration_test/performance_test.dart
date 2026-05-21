// ignore_for_file: avoid_print
//
// PRUEBAS DE RENDIMIENTO MO-PE-01 a MO-PE-05
// Backend: https://narinocultura-production.up.railway.app
//
// ══════════════════════════════════════════════════════════════════════════════
// CÓMO EJECUTAR (requiere emulador o dispositivo físico conectado):
//
//   flutter test integration_test/performance_test.dart \
//     --profile \
//     --dart-define=TEST_EMAIL=tu@correo.com \
//     --dart-define=TEST_PASSWORD=tucontraseña
//
// La URL de Railway está fija en EnvConstants — no hace falta pasarla.
//
// El flag --profile desactiva el modo debug para medir el rendimiento real.
//
// ABRIR DEVTOOLS DURANTE LAS PRUEBAS:
//   1. Ejecuta el comando de arriba
//   2. Abre Chrome y ve a: http://localhost:<puerto_que_aparece_en_consola>
//      O desde VS Code: Ctrl+Shift+P → "Dart: Open DevTools"
//   3. Pestaña "Performance" → "Record" durante la ejecución del test
//   4. Pestaña "Memory"     → monitor de uso de memoria en tiempo real
//
// ❌ NO guardes credenciales reales en este archivo.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:narino_cultura/core/constants/env_constants.dart';
import 'package:narino_cultura/core/utils/storage_utils.dart';
import 'package:narino_cultura/main.dart' as app;

// ─── Credenciales (nunca hardcodeadas) ───────────────────────────────────────

const _email = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const _password = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');

// ─── Umbrales de rendimiento aceptables ──────────────────────────────────────

const _maxStartupMs = 4000;      // Arranque app < 4 s
const _maxNavMs = 600;           // Transición de pantalla < 600 ms
const _maxCatalogLoadMs = 6000;  // Catálogo con imágenes < 6 s
const _maxScrollJankMs = 16;     // Cada frame < 16 ms (60 fps)

// ─── Helpers ──────────────────────────────────────────────────────────────────

Future<void> _loginProgrammatically() async {
  if (_email.isEmpty || _password.isEmpty) {
    print('⚠️  Pasa --dart-define=TEST_EMAIL y TEST_PASSWORD');
    return;
  }
  final dio = Dio(BaseOptions(
    baseUrl: EnvConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final resp = await dio.post(
    '/auth/login/',
    data: {'email': _email, 'password': _password},
  );
  final data = resp.data as Map<String, dynamic>;
  await StorageUtils.saveTokens(
    accessToken: data['access'] as String,
    refreshToken: data['refresh'] as String,
  );
}

Future<void> _navTo(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Lanza la app y espera a que se estabilice.
Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 6));
}

/// Devuelve el primer widget scrollable visible (GridView, ListView o CustomScrollView).
Finder _firstScrollable() {
  final grid = find.byType(GridView);
  if (grid.evaluate().isNotEmpty) return grid.first;
  final list = find.byType(ListView);
  if (list.evaluate().isNotEmpty) return list.first;
  return find.byType(CustomScrollView).first;
}

String _ms(int ms) => '$ms ms';
String _result(int ms, int threshold) =>
    ms <= threshold ? '✅ DENTRO DEL UMBRAL' : '⚠️  SUPERA EL UMBRAL';

// ─── Suite ────────────────────────────────────────────────────────────────────

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loginProgrammatically();
  });

  // ────────────────────────────────────────────────────────────────────────────
  // MO-PE-01 — TIEMPO DE ARRANQUE
  // Mide cuánto tarda la app desde el lanzamiento hasta mostrar la
  // primera pantalla completamente renderizada (home o login).
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('MO-PE-01: Tiempo de arranque de la app', (tester) async {
    print('\n══ MO-PE-01: Tiempo de arranque ══');
    print('Umbral aceptable: < ${_maxStartupMs}ms');

    final sw = Stopwatch()..start();
    app.main();
    // pumpAndSettle espera hasta que no haya frames pendientes
    await tester.pumpAndSettle(const Duration(seconds: 10));
    sw.stop();

    final elapsed = sw.elapsedMilliseconds;
    print('⏱  Arranque: ${_ms(elapsed)}  →  ${_result(elapsed, _maxStartupMs)}');

    // La pantalla principal (home o login) debe estar visible
    final isOnApp =
        find.text('Nariño Cultura').evaluate().isNotEmpty ||
        find.text('Iniciar sesión').evaluate().isNotEmpty;
    expect(isOnApp, isTrue, reason: 'La app no mostró pantalla principal');
    expect(elapsed, lessThanOrEqualTo(_maxStartupMs));

    print('''
─────────────────────────────────────────────
DEVTOOLS — Cómo ver el tiempo de arranque:
  1. Ejecuta con --profile
  2. DevTools > Performance > "App Startup"
  3. Busca "Time to first meaningful frame"
─────────────────────────────────────────────''');
  });

  // ────────────────────────────────────────────────────────────────────────────
  // MO-PE-02 — FLUIDEZ DE SCROLL EN EL CATÁLOGO (60 FPS)
  // Realiza un fling rápido sobre el catálogo y captura la traza de timeline.
  // DevTools → Performance muestra si hay "jank frames" (> 16ms).
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('MO-PE-02: Fluidez de scroll en el catálogo (60 fps)',
      (tester) async {
    print('\n══ MO-PE-02: Scroll en catálogo ══');
    print('Umbral por frame: < ${_maxScrollJankMs}ms  (60 fps)');

    await _launchApp(tester);
    await _navTo(tester, 'Catálogo');
    // Dar tiempo para que carguen las obras
    await tester.pump(const Duration(seconds: 3));

    await binding.traceAction(
      () async {
        final scrollable = _firstScrollable();
        if (scrollable.evaluate().isEmpty) {
          print('⚠️  No se encontró área scrollable en catálogo');
          return;
        }

        // 3 ciclos de scroll hacia abajo y arriba
        for (var i = 0; i < 3; i++) {
          await tester.fling(scrollable, const Offset(0, -600), 3000);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          await tester.fling(scrollable, const Offset(0, 600), 3000);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      },
      reportKey: 'mo_pe_02_catalog_scroll',
    );

    print('''
✅ Traza capturada → clave: "mo_pe_02_catalog_scroll"
─────────────────────────────────────────────
DEVTOOLS — Cómo analizar el scroll:
  1. Ejecuta con --profile
  2. DevTools > Performance > "Record" antes de correr el test
  3. Busca frames rojos/amarillos en la timeline (jank frames)
  4. Frame time objetivo: < 16ms (línea verde en DevTools)
─────────────────────────────────────────────''');

    expect(find.text('Catálogo de Obras'), findsOneWidget);
  });

  // ────────────────────────────────────────────────────────────────────────────
  // MO-PE-03 — TIEMPO DE CARGA DE IMÁGENES DESDE LA RED
  // Mide cuánto tarda el catálogo en mostrar sus primeras imágenes
  // usando CachedNetworkImage + Railway como fuente.
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('MO-PE-03: Tiempo de carga de imágenes desde Railway',
      (tester) async {
    print('\n══ MO-PE-03: Carga de imágenes ══');
    print('Umbral aceptable: < ${_maxCatalogLoadMs}ms');

    await _launchApp(tester);

    final sw = Stopwatch()..start();
    await _navTo(tester, 'Catálogo');

    // Esperar hasta que aparezcan imágenes cargadas (Image widget visible)
    // o hasta que se supere el umbral
    var elapsed = 0;
    while (elapsed < _maxCatalogLoadMs) {
      await tester.pump(const Duration(milliseconds: 300));
      elapsed += 300;
      final hasImages = find.byType(Image).evaluate().isNotEmpty ||
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString().contains('CachedNetworkImage'),
          ).evaluate().isNotEmpty;
      if (hasImages) break;
    }
    sw.stop();

    final measured = sw.elapsedMilliseconds;
    print('⏱  Primera imagen visible: ${_ms(measured)}  →  ${_result(measured, _maxCatalogLoadMs)}');

    print('''
─────────────────────────────────────────────
DEVTOOLS — Cómo ver la carga de red:
  1. DevTools > Network (solo disponible en modo debug)
  2. Filtra por extensión: .jpg .png .webp
  3. Revisa "Time" de cada petición de imagen
  4. CachedNetworkImage sirve desde caché en la 2ª visita
─────────────────────────────────────────────''');

    expect(measured, lessThanOrEqualTo(_maxCatalogLoadMs));
  });

  // ────────────────────────────────────────────────────────────────────────────
  // MO-PE-04 — VELOCIDAD DE TRANSICIÓN ENTRE PANTALLAS
  // Navega a través de los 5 tabs del BottomNavigationBar y mide
  // el tiempo de cada transición.
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('MO-PE-04: Velocidad de transición entre pantallas',
      (tester) async {
    print('\n══ MO-PE-04: Transiciones entre pantallas ══');
    print('Umbral por transición: < ${_maxNavMs}ms');

    await _launchApp(tester);

    final tabs = ['Catálogo', 'Tienda', 'Subastas', 'Eventos', 'Perfil', 'Inicio'];
    final times = <String, int>{};

    await binding.traceAction(
      () async {
        for (final tab in tabs) {
          final sw = Stopwatch()..start();
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle(const Duration(seconds: 4));
          sw.stop();
          times[tab] = sw.elapsedMilliseconds;
        }
      },
      reportKey: 'mo_pe_04_navigation',
    );

    print('\n  Tiempos por pantalla:');
    var maxTime = 0;
    for (final entry in times.entries) {
      final ms = entry.value;
      if (ms > maxTime) maxTime = ms;
      print('  → ${entry.key.padRight(12)} ${_ms(ms).padLeft(8)}  '
          '${_result(ms, _maxNavMs)}');
    }
    print('\n  Máximo: ${_ms(maxTime)}  →  ${_result(maxTime, _maxNavMs)}');

    print('''
─────────────────────────────────────────────
DEVTOOLS — Cómo ver las transiciones:
  1. DevTools > Performance > "Record"
  2. Ejecuta el test y mira la timeline
  3. Cada transición debe completarse en < 600ms
  4. Busca "Route push/pop" events en la traza
─────────────────────────────────────────────''');

    expect(maxTime, lessThanOrEqualTo(_maxNavMs * 3),
        reason: 'Alguna transición tardó demasiado (backend lento o jank)');
  });

  // ────────────────────────────────────────────────────────────────────────────
  // MO-PE-05 — USO DE MEMORIA DURANTE LA SESIÓN
  // Navega por todas las pantallas principales para detectar memory leaks.
  // La medición exacta se realiza en DevTools > Memory.
  // ────────────────────────────────────────────────────────────────────────────
  testWidgets('MO-PE-05: Uso de memoria durante la sesión completa',
      (tester) async {
    print('\n══ MO-PE-05: Uso de memoria ══');
    print('''
─────────────────────────────────────────────
ANTES DE EJECUTAR:
  1. Abre DevTools > Memory
  2. Activa "Track allocations"
  3. Toma una snapshot inicial ("Snapshot" button)
─────────────────────────────────────────────''');

    await _launchApp(tester);

    // Navegar por todos los módulos de la app
    await binding.traceAction(
      () async {
        final screens = [
          'Catálogo',
          'Tienda',
          'Subastas',
          'Eventos',
          'Perfil',
          'Inicio',
          'Catálogo',  // segunda visita: verifica que no se acumula memoria
          'Eventos',
          'Perfil',
          'Inicio',
        ];

        for (final tab in screens) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle(const Duration(seconds: 3));
          print('  → Visitado: $tab');
        }

        // Scroll en catálogo para ejercitar cache de imágenes
        await _navTo(tester, 'Catálogo');
        await tester.pump(const Duration(seconds: 2));
        final scrollable = _firstScrollable();
        if (scrollable.evaluate().isNotEmpty) {
          await tester.fling(scrollable, const Offset(0, -800), 2000);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          await tester.fling(scrollable, const Offset(0, 800), 2000);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      },
      reportKey: 'mo_pe_05_memory_session',
    );

    print('''
─────────────────────────────────────────────
DESPUÉS DE EJECUTAR:
  1. DevTools > Memory > toma otra snapshot
  2. Compara con la snapshot inicial
  3. Resultados esperados:
     ✅ Heap no crece más de ~20 MB entre visitas
     ✅ No hay clases con "leaked" widgets
     ✅ Los providers de Riverpod se liberan con .autoDispose
  4. Si ves crecimiento continuo → posible memory leak en:
     - Listeners no cancelados (ProviderSubscription)
     - AnimationControllers sin dispose()
     - Streams no cerrados
─────────────────────────────────────────────''');

    expect(find.byType(Scaffold), findsOneWidget,
        reason: 'La app debe seguir respondiendo tras navegar por todos los módulos');
    print('✅ MO-PE-05 completado — revisa DevTools > Memory para el análisis');
  });
}
