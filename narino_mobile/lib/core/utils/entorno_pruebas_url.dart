import 'package:narino_cultura/core/utils/decision_entorno.dart';

/// Lógica pura (sin dart-define) para decidir si una URL de API es segura para pruebas de integración.
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

  /// Verdadero si el host es localhost, 127.0.0.1, 10.0.2.2 o una IP privada 192.168.x.x / 10.x.x.x.
  static bool esLocal(String url) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase() ?? '';
    if (host.isEmpty) return false;
    if (host == 'localhost' || host == '127.0.0.1') return true;
    return RegExp(r'^(192\.168|10)\.\d{1,3}(\.\d{1,3}){1,2}$').hasMatch(host);
  }
}
