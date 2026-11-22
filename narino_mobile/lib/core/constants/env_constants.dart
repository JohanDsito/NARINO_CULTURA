/// URLs del backend. Por defecto apuntan a producción; para otro servidor se compila con
/// `--dart-define=API_BASE_URL=https://otro-servidor` (y opcionalmente `WS_BASE_URL`).
class EnvConstants {
  EnvConstants._();

  static const String _produccion = 'https://narinocultura-production.up.railway.app';

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _produccion);

  static const String _wsBaseUrl = String.fromEnvironment('WS_BASE_URL');

  /// WebSocket de subastas. Si no se define `WS_BASE_URL`, se deriva de [apiBaseUrl] (https → wss, http → ws).
  static String get auctionWsBaseUrl => _wsBaseUrl.isNotEmpty
      ? _wsBaseUrl
      : '${apiBaseUrl.replaceFirst(RegExp('^http'), 'ws')}/ws/auctions/';
}
