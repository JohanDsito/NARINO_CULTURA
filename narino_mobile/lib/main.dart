import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/raiz_confianza.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await RaizConfianza.instalar(); // ISRG Root X1 para Android < 7.1.1
  } catch (e) {
    // Si falla, la app arranca igual: solo Android < 7.1.1 quedaría sin red.
    debugPrint('No se pudo instalar ISRG Root X1: $e');
  }
  ApiClient.instance.init(); // interceptor JWT activo
  runApp(
    const ProviderScope(
      child: NarinoCulturaApp(),
    ),
  );
}
