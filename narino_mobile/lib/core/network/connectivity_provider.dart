import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` si el teléfono tiene alguna red (wifi, datos…), `false` si no.
///
/// No garantiza que el servidor responda, solo que hay red: sirve para saber
/// cuándo vale la pena reintentar (MO-DISP-02). En los tests se reemplaza por
/// un stream controlado.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none))
      .distinct();
});
