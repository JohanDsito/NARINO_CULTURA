import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:narino_cultura/features/profile/presentation/widgets/disciplinas.dart';

void main() {
  group('disciplinaDe', () {
    test('reconoce el valor de la web y sus variantes', () {
      for (final v in ['Pintor', 'pintora', 'Pintura', ' PINTURA ']) {
        expect(disciplinaDe(v)?.value, 'Pintor', reason: v);
      }
      expect(disciplinaDe('Fotografía')?.value, 'Fotógrafo');
      expect(disciplinaDe('artesania')?.value, 'Artesano');
    });

    test('devuelve null para disciplinas que no están en la lista', () {
      expect(disciplinaDe('Danza'), isNull);
      expect(disciplinaDe(''), isNull);
      expect(disciplinaDe(null), isNull);
    });
  });

  test('esDisciplinaMusical acepta Música, Musica y Músico', () {
    for (final v in ['Música', 'Musica', 'Músico', 'musico']) {
      expect(esDisciplinaMusical(v), isTrue, reason: v);
    }
    expect(esDisciplinaMusical('Pintor'), isFalse);
    expect(esDisciplinaMusical(null), isFalse);
  });

  group('normalizarEnlace', () {
    test('vacío se queda vacío (permite borrar la red)', () {
      expect(normalizarEnlace('website', '   '), '');
    });

    test('agrega https:// si falta', () {
      expect(normalizarEnlace('website', 'misitio.co'), 'https://misitio.co');
      expect(normalizarEnlace('website', 'http://a.co'), 'http://a.co');
    });

    test('convierte @usuario en el enlace de cada red', () {
      expect(normalizarEnlace('instagram', '@valery'),
          'https://instagram.com/valery');
      expect(normalizarEnlace('tiktok', '@valery'),
          'https://www.tiktok.com/@valery');
    });
  });
}
