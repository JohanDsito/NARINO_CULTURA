import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/utils/json_num.dart';

void main() {
  group('parseJsonDouble', () {
    test('acepta int y double', () {
      expect(parseJsonDouble(3), 3.0);
      expect(parseJsonDouble(-77.2811), -77.2811);
    });
    test('acepta texto numérico (DecimalField de Django)', () {
      expect(parseJsonDouble('1.213611'), 1.213611);
      expect(parseJsonDouble(' -77.281100 '), -77.2811);
    });
    test('null y texto inválido dan null', () {
      expect(parseJsonDouble(null), isNull);
      expect(parseJsonDouble(''), isNull);
      expect(parseJsonDouble('abc'), isNull);
      expect(parseJsonDouble(true), isNull);
    });
  });

  group('parseJsonDoubleOr', () {
    test('usa el valor por defecto si no se puede leer', () {
      expect(parseJsonDoubleOr('x', 5), 5.0);
      expect(parseJsonDoubleOr('2.5', 5), 2.5);
    });
  });
}
