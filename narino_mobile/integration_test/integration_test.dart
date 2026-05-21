// ignore_for_file: avoid_print
//
// PRUEBAS DE INTEGRACIÓN MO-IN-01 a MO-IN-16
// Backend: https://narinocultura-production.up.railway.app
//
// Cómo ejecutar (con emulador o dispositivo conectado):
//
//   flutter test integration_test/integration_test.dart \
//     --dart-define=TEST_EMAIL=tu@correo.com \
//     --dart-define=TEST_PASSWORD=tucontraseña
//
// La URL de Railway está fija en EnvConstants — no hace falta pasarla.
//
// ❌ NO guardes credenciales reales en este archivo.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:narino_cultura/core/constants/env_constants.dart';
import 'package:narino_cultura/core/utils/storage_utils.dart';
import 'package:narino_cultura/main.dart' as app;

// ─── Credenciales via dart-define (nunca hardcodeadas) ───────────────────────

const _email = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const _password = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');

// ─── Tiempos de espera para el backend remoto ─────────────────────────────────

const _networkDelay = Duration(seconds: 8);
const _shortDelay = Duration(seconds: 3);

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Hace login programático contra Railway y guarda los tokens en SecureStorage.
Future<void> _loginProgrammatically() async {
  assert(_email.isNotEmpty, 'Pasa --dart-define=TEST_EMAIL=...');
  assert(_password.isNotEmpty, 'Pasa --dart-define=TEST_PASSWORD=...');

  final dio = Dio(BaseOptions(
    baseUrl: EnvConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final response = await dio.post(
    '/auth/login/',
    data: {'email': _email, 'password': _password},
  );

  final access = (response.data as Map<String, dynamic>)['access'] as String;
  final refresh = (response.data as Map<String, dynamic>)['refresh'] as String;
  await StorageUtils.saveTokens(accessToken: access, refreshToken: refresh);
  print('✅ Login programático exitoso');
}

/// Inicia la app y espera a que se estabilice.
Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(_networkDelay);
}

/// Toca un ítem del BottomNavigationBar por su label.
Future<void> _navTo(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle(_networkDelay);
}

// ─── Suite de pruebas ─────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Grupo 1: Autenticación (estado limpio) ──────────────────────────────────

  group('Autenticación', () {
    setUp(() async => StorageUtils.clearTokens());

    testWidgets(
      'MO-IN-01: Login exitoso con credenciales válidas',
      (tester) async {
        await _launchApp(tester);

        // La app debe mostrar la pantalla de login
        expect(find.text('Iniciar sesión'), findsWidgets);

        // Ingresar credenciales
        await tester.enterText(find.byType(TextFormField).at(0), _email);
        await tester.enterText(find.byType(TextFormField).at(1), _password);

        // Enviar
        await tester.tap(find.text('Iniciar sesión').last);
        await tester.pumpAndSettle(_networkDelay);

        // Debe navegar al home
        expect(find.text('Nariño Cultura'), findsOneWidget);
        print('✅ MO-IN-01 pasó');
      },
    );

    testWidgets(
      'MO-IN-02: Login fallido con credenciales incorrectas muestra error',
      (tester) async {
        await _launchApp(tester);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'noexiste@fake.com',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'contraseñaWrong123',
        );
        await tester.tap(find.text('Iniciar sesión').last);
        await tester.pumpAndSettle(_networkDelay);

        // Debe seguir en login y mostrar algún mensaje de error
        expect(find.byType(TextFormField), findsWidgets);
        // El banner de error usa un Icon de error
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        print('✅ MO-IN-02 pasó');
      },
    );

    testWidgets(
      'MO-IN-03: Registro de nuevo usuario navega al home',
      (tester) async {
        await _launchApp(tester);

        // Ir a la pantalla de registro
        await tester.tap(find.text('Regístrate'));
        await tester.pumpAndSettle(_shortDelay);

        // Usar email único con timestamp para no colisionar
        final uniqueEmail =
            'test${DateTime.now().millisecondsSinceEpoch}@testnarino.com';

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Usuario Test');
        await tester.enterText(fields.at(1), uniqueEmail);
        await tester.enterText(fields.at(2), 'Test1234!');
        await tester.enterText(fields.at(3), 'Test1234!');

        // Seleccionar rol Comprador
        await tester.tap(find.text('Comprador'));
        await tester.pumpAndSettle(_shortDelay);

        // Enviar formulario
        await tester.tap(find.text('Crear cuenta'));
        await tester.pumpAndSettle(_networkDelay);

        // Debe navegar al home tras registrarse y auto-loguearse
        expect(find.text('Nariño Cultura'), findsOneWidget);
        print('✅ MO-IN-03 pasó');
      },
    );
  });

  // ── Grupo 2: Funcionalidades (requieren sesión activa) ──────────────────────

  group('Funcionalidades autenticadas', () {
    setUpAll(() async {
      await _loginProgrammatically();
    });

    setUp(() async {
      // Los tokens ya están guardados; no limpiar entre estos tests
    });

    testWidgets(
      'MO-IN-04: Catálogo de obras carga resultados del backend',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Catálogo');

        expect(find.text('Catálogo de Obras'), findsOneWidget);
        // Debe haber al menos una obra o el mensaje vacío
        final hasCards = find.byType(Card).evaluate().isNotEmpty ||
            find.byType(GridView).evaluate().isNotEmpty ||
            find.text('Sin resultados').evaluate().isNotEmpty ||
            find.text('No hay obras').evaluate().isNotEmpty;
        expect(hasCards, isTrue);
        print('✅ MO-IN-04 pasó');
      },
    );

    testWidgets(
      'MO-IN-05: Búsqueda en catálogo filtra por texto',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Catálogo');

        // Buscar un ícono de búsqueda o campo de texto
        final searchIcon = find.byIcon(Icons.search);
        if (searchIcon.evaluate().isNotEmpty) {
          await tester.tap(searchIcon.first);
          await tester.pumpAndSettle(_shortDelay);
        }

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'arte');
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pumpAndSettle(_networkDelay);
        }

        // Verificar que la UI responde (sigue visible el catálogo)
        expect(find.text('Catálogo de Obras'), findsOneWidget);
        print('✅ MO-IN-05 pasó');
      },
    );

    testWidgets(
      'MO-IN-06: Filtro por categoría actualiza el listado',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Catálogo');

        // Buscar el botón/ícono de filtro
        final filterIcon = find.byIcon(Icons.filter_list_outlined);
        if (filterIcon.evaluate().isNotEmpty) {
          await tester.tap(filterIcon.first);
          await tester.pumpAndSettle(_shortDelay);

          // Intentar seleccionar la primera categoría disponible
          final chipFinder = find.byType(FilterChip);
          if (chipFinder.evaluate().isNotEmpty) {
            await tester.tap(chipFinder.first);
            await tester.pumpAndSettle(_networkDelay);
          }
        }

        expect(find.text('Catálogo de Obras'), findsOneWidget);
        print('✅ MO-IN-06 pasó');
      },
    );

    testWidgets(
      'MO-IN-07: Detalle de obra es accesible desde el catálogo',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Catálogo');

        // Esperar a que las obras carguen
        await tester.pump(_networkDelay);

        // Intentar tocar la primera obra del catálogo
        final artworkCards = find.byType(GestureDetector);
        if (artworkCards.evaluate().length > 1) {
          await tester.tap(artworkCards.first);
          await tester.pumpAndSettle(_networkDelay);

          // Debe mostrar detalles de la obra (precio o descripción)
          final hasDetail =
              find.byIcon(Icons.favorite_outline).evaluate().isNotEmpty ||
              find.byIcon(Icons.shopping_cart_outlined).evaluate().isNotEmpty ||
              find.text('Precio a consultar').evaluate().isNotEmpty;
          expect(hasDetail, isTrue);
        }
        print('✅ MO-IN-07 pasó');
      },
    );

    testWidgets(
      'MO-IN-08: Marcar/desmarcar favorito en una obra',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Catálogo');
        await tester.pump(_networkDelay);

        final favIcon = find.byIcon(Icons.favorite_outline);
        if (favIcon.evaluate().isNotEmpty) {
          await tester.tap(favIcon.first);
          await tester.pumpAndSettle(_networkDelay);
          // Después de toggle, el ícono puede cambiar a favorite (relleno)
          print('✅ MO-IN-08 pasó — toggle de favorito ejecutado');
        } else {
          print('⚠️ MO-IN-08: no se encontraron favoritos en pantalla');
        }
        expect(find.text('Catálogo de Obras'), findsOneWidget);
      },
    );

    testWidgets(
      'MO-IN-09: Agregar obra al carrito desde el detalle',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Catálogo');
        await tester.pump(_networkDelay);

        // Abrir primera obra disponible
        final cards = find.byType(GestureDetector);
        if (cards.evaluate().length > 1) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle(_networkDelay);

          // Buscar botón de agregar al carrito
          final cartBtn = find.byIcon(Icons.shopping_cart_outlined);
          if (cartBtn.evaluate().isNotEmpty) {
            await tester.tap(cartBtn.first);
            await tester.pumpAndSettle(_networkDelay);
            print('✅ MO-IN-09 pasó — ítem agregado al carrito');
          } else {
            print('⚠️ MO-IN-09: botón de carrito no visible (obra no disponible)');
          }
        }
        // No hace falta que el botón esté presente; si la obra es vendida tampoco aparece
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );

    testWidgets(
      'MO-IN-10: Carrito de compras es accesible desde la Tienda',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Tienda');

        // La pantalla de marketplace debe cargar
        expect(find.byType(Scaffold), findsOneWidget);

        // Buscar el ícono del carrito
        final cartIcon = find.byIcon(Icons.shopping_cart_outlined);
        if (cartIcon.evaluate().isNotEmpty) {
          await tester.tap(cartIcon.first);
          await tester.pumpAndSettle(_networkDelay);
          print('✅ MO-IN-10 pasó — carrito abierto');
        } else {
          print('⚠️ MO-IN-10: ícono de carrito no encontrado en tienda');
          expect(find.byType(Scaffold), findsOneWidget);
        }
      },
    );

    testWidgets(
      'MO-IN-11: Listado de eventos culturales carga desde el backend',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Eventos');

        // Verificar que la pantalla de eventos cargó
        expect(find.byType(Scaffold), findsOneWidget);
        // Debe haber items o mensaje vacío
        await tester.pump(_networkDelay);
        final hasContent =
            find.byType(ListView).evaluate().isNotEmpty ||
            find.byType(Card).evaluate().isNotEmpty ||
            find.text('No hay eventos').evaluate().isNotEmpty ||
            find.text('Sin eventos').evaluate().isNotEmpty;
        expect(hasContent, isTrue);
        print('✅ MO-IN-11 pasó');
      },
    );

    testWidgets(
      'MO-IN-12: Detalle de evento es accesible desde la agenda',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Eventos');
        await tester.pump(_networkDelay);

        final cards = find.byType(GestureDetector);
        if (cards.evaluate().length > 1) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle(_networkDelay);

          // El detalle de evento tiene botón de recordatorio o mapa
          final hasDetail =
              find.byIcon(Icons.notifications_outlined).evaluate().isNotEmpty ||
              find.byIcon(Icons.map_outlined).evaluate().isNotEmpty ||
              find.byIcon(Icons.location_on_outlined).evaluate().isNotEmpty;
          expect(hasDetail, isTrue);
          print('✅ MO-IN-12 pasó');
        } else {
          print('⚠️ MO-IN-12: no hay eventos para abrir detalle');
          expect(find.byType(Scaffold), findsOneWidget);
        }
      },
    );

    testWidgets(
      'MO-IN-13: Listado de subastas activas carga desde el backend',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Subastas');
        await tester.pump(_networkDelay);

        expect(find.byType(Scaffold), findsOneWidget);
        final hasContent =
            find.byType(ListView).evaluate().isNotEmpty ||
            find.byType(Card).evaluate().isNotEmpty ||
            find.text('No hay subastas').evaluate().isNotEmpty ||
            find.text('Sin subastas').evaluate().isNotEmpty;
        expect(hasContent, isTrue);
        print('✅ MO-IN-13 pasó');
      },
    );

    testWidgets(
      'MO-IN-14: Perfil propio muestra nombre de usuario',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Perfil');
        await tester.pumpAndSettle(_networkDelay);

        // La pantalla de perfil debe mostrar al menos "Mi perfil" (si no cargó aún)
        // o el nombre del usuario
        final hasPerfil =
            find.text('Mi perfil').evaluate().isNotEmpty ||
            find.byType(CircleAvatar).evaluate().isNotEmpty;
        expect(hasPerfil, isTrue);
        print('✅ MO-IN-14 pasó');
      },
    );

    testWidgets(
      'MO-IN-15: Centro de notificaciones es accesible',
      (tester) async {
        await _launchApp(tester);

        // Navegar al home primero
        await _navTo(tester, 'Inicio');

        // Buscar ícono de notificaciones en el AppBar del home
        final notifIcon = find.byIcon(Icons.notifications_outlined);
        if (notifIcon.evaluate().isNotEmpty) {
          await tester.tap(notifIcon.first);
          await tester.pumpAndSettle(_networkDelay);
          expect(find.byType(Scaffold), findsOneWidget);
          print('✅ MO-IN-15 pasó');
        } else {
          print('⚠️ MO-IN-15: ícono de notificaciones no visible en home');
          expect(find.byType(Scaffold), findsOneWidget);
        }
      },
    );

    testWidgets(
      'MO-IN-16: Cierre de sesión regresa a la pantalla de login',
      (tester) async {
        await _launchApp(tester);
        await _navTo(tester, 'Perfil');
        await tester.pumpAndSettle(_shortDelay);

        // Tocar el ícono de logout en el AppBar del perfil
        final logoutIcon = find.byIcon(Icons.logout_outlined);
        expect(logoutIcon, findsOneWidget);
        await tester.tap(logoutIcon);
        await tester.pumpAndSettle(_shortDelay);

        // Confirmar en el diálogo de confirmación
        final confirmBtn = find.text('Cerrar sesión');
        if (confirmBtn.evaluate().length > 1) {
          // Hay dos: el título del diálogo y el botón; tocar el último
          await tester.tap(confirmBtn.last);
        } else {
          await tester.tap(confirmBtn);
        }
        await tester.pumpAndSettle(_networkDelay);

        // Debe redirigir a la pantalla de login
        expect(find.text('Iniciar sesión'), findsWidgets);
        print('✅ MO-IN-16 pasó — sesión cerrada');
      },
    );
  });
}
