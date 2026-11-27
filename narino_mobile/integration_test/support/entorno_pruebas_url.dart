import 'decision_entorno.dart';

/// Lógica pura (sin dart-define) para decidir si una URL de API es segura para pruebas de integración.
/// Vive fuera de `lib/` porque solo la usan las pruebas; no se compila en la app.
class EntornoPruebasUrl {
  EntornoPruebasUrl._();

  /// Fragmentos que identifican producción.
  static const List<String> _marcasProduccion = ['railway.app', 'narinocultura'];

  /// Aborta si la URL está vacía o contiene una marca de producción; si no, permite.
  static DecisionEntorno decidir(String url) {
    final limpia = url.trim().toLowerCase();
    if (limpia.isEmpty) return DecisionEntorno.abortar;
    if (_marcasProduccion.any(limpia.contains)) return DecisionEntorno.abortar;
    return DecisionEntorno.permitir;
  }

  /// Verdadero si el host es localhost, loopback (127.x, ::1) o una IPv4 privada
  /// (10.x, 172.16–31.x, 192.168.x; incluye 10.0.2.2 del emulador Android).
  static bool esLocal(String url) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase() ?? '';
    if (host.isEmpty) return false;
    if (host == 'localhost' || host == '::1') return true;
    final partes = host.split('.');
    if (partes.length != 4) return false;
    final octetos = partes.map(int.tryParse).toList();
    if (octetos.any((o) => o == null || o < 0 || o > 255)) return false;
    final a = octetos[0]!, b = octetos[1]!;
    return a == 127 || a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
  }
}
