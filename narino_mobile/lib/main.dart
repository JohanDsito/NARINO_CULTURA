import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.init(); // interceptor JWT activo
  runApp(
    const ProviderScope(
      child: NarinoCulturaApp(),
    ),
  );
}
