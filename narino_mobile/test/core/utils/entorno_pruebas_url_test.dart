import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/utils/decision_entorno.dart';
import 'package:narino_cultura/core/utils/entorno_pruebas_url.dart';

void main() {
  group('EntornoPruebasUrl.decidir', () {
    test('aborta con la URL de producción', () {
      expect(EntornoPruebasUrl.decidir('https://narinocultura-production.up.railway.app'), DecisionEntorno.abortar);
    });
    test('aborta con cualquier railway.app o narinocultura, sin importar mayúsculas', () {
      expect(EntornoPruebasUrl.decidir('https://otro.RAILWAY.app'), DecisionEntorno.abortar);
      expect(EntornoPruebasUrl.decidir('https://api.narinocultura.com'), DecisionEntorno.abortar);
    });
    test('aborta si está vacía', () {
      expect(EntornoPruebasUrl.decidir('  '), DecisionEntorno.abortar);
    });
    test('permite servidores locales', () {
      expect(EntornoPruebasUrl.decidir('http://192.168.1.10:8000'), DecisionEntorno.permitir);
      expect(EntornoPruebasUrl.decidir('http://10.0.2.2:8000'), DecisionEntorno.permitir);
    });
  });

  group('EntornoPruebasUrl.esLocal', () {
    test('reconoce hosts locales', () {
      for (final u in [
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8000',
        'http://192.168.0.5:8000',
        'http://10.1.2.3',
      ]) {
        expect(EntornoPruebasUrl.esLocal(u), isTrue, reason: u);
      }
    });
    test('rechaza hosts públicos o inválidos', () {
      for (final u in [
        'https://narinocultura-production.up.railway.app',
        'http://8.8.8.8:8000',
        'http://172.16.0.1',
        'https://staging.ejemplo.com',
        '',
      ]) {
        expect(EntornoPruebasUrl.esLocal(u), isFalse, reason: u);
      }
    });
  });
}
