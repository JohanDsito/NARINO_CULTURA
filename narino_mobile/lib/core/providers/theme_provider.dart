import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kThemeKey = 'app_theme_mode';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // El design system parte en modo oscuro ("body.dark" por defecto).
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    String? value;
    try {
      value = await _storage.read(key: _kThemeKey);
    } catch (_) {
      // Llavero no disponible (p. ej. tras restaurar una copia en Android):
      // se queda el tema por defecto.
      return;
    }
    if (!mounted) return;
    state = switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  /// Alterna claro ↔ oscuro (botón ☀️/🌙 del header).
  Future<void> toggle(Brightness current) => setMode(
      current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final stored = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    try {
      await _storage.write(key: _kThemeKey, value: stored);
    } catch (_) {
      // El cambio aplica igual en esta sesión aunque no se pueda guardar.
    }
  }
}
