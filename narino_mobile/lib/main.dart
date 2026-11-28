import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/raiz_confianza.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RaizConfianza.instalar(); // ISRG Root X1 para Android < 7.1.1
  ApiClient.instance.init(); // interceptor JWT activo
  runApp(
    const ProviderScope(
      child: NarinoCulturaApp(),
    ),
  );
}
