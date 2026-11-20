import 'package:flutter/foundation.dart';

/// Aviso de que la sesión terminó sin que la persona cerrara sesión
/// (el token de renovación ya no sirve). MO-SEG-04.
///
/// El router lo escucha (`refreshListenable`) para mandar al login, la app
/// limpia los datos del usuario y el login muestra "Tu sesión expiró".
abstract final class SessionExpiry {
  /// Cambia de valor cada vez que la sesión expira.
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static bool _messagePending = false;

  static void expire() {
    _messagePending = true;
    notifier.value++;
  }

  /// `true` una sola vez después de expirar: para mostrar el aviso en el login.
  static bool consumeMessage() {
    final pending = _messagePending;
    _messagePending = false;
    return pending;
  }
}
