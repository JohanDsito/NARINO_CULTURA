import 'package:narino_cultura/core/constants/env_constants.dart';
import 'package:narino_cultura/core/utils/decision_entorno.dart';
import 'package:narino_cultura/core/utils/entorno_pruebas_url.dart';

/// Guard de seguridad de las pruebas de integración: evita ensuciar producción.
class EntornoPruebas {
  EntornoPruebas._();

  /// Se llama al inicio de `main()`. Lanza [StateError] si falta API_BASE_URL o apunta a producción.
  static void exigirEntornoSeguro() {
    if (!const bool.hasEnvironment('API_BASE_URL')) {
      throw StateError(
        'Falta --dart-define=API_BASE_URL=http://<IP-del-PC>:8000. '
        'Sin él las pruebas usarían PRODUCCIÓN. Ver integration_test/README.md.',
      );
    }
    const url = EnvConstants.apiBaseUrl;
    if (EntornoPruebasUrl.decidir(url) == DecisionEntorno.abortar) {
      throw StateError('ABORTADO: API_BASE_URL ($url) es producción o inválida. Usa un backend local.');
    }
  }

  /// Verdadero si el backend configurado es local (permite pruebas que crean datos, como el registro).
  static bool get esBackendLocal => EntornoPruebasUrl.esLocal(EnvConstants.apiBaseUrl);
}
