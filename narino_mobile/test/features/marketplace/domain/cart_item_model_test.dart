import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/marketplace/domain/cart_item_model.dart';

void main() {
  group('CartItemModel.fromJson', () {
    test('mapea los campos en inglés del backend', () {
      final item = CartItemModel.fromJson({
        'id': '10',
        'artwork': 'obra-1',
        'artwork_title': 'Barniz de Pasto',
        'artista_nombre': 'Ana Díaz',
        'artwork_price': '150000',
        'imagen_url': 'https://cdn.test/1.jpg',
      });

      expect(item.id, '10');
      expect(item.obraId, 'obra-1');
      expect(item.obraTitulo, 'Barniz de Pasto');
      expect(item.artistaNombre, 'Ana Díaz');
      expect(item.precio, 150000);
      expect(item.imagenUrl, 'https://cdn.test/1.jpg');
    });

    test('usa los nombres de campo en español como respaldo', () {
      final item = CartItemModel.fromJson({
        'id': '10',
        'obra_id': 'obra-2',
        'obra_titulo': 'Tamo de Pasto',
        'precio': '90000',
      });

      expect(item.obraId, 'obra-2');
      expect(item.obraTitulo, 'Tamo de Pasto');
      expect(item.precio, 90000);
    });

    test('usa cadenas vacías y precio 0 cuando faltan las claves', () {
      final item = CartItemModel.fromJson({});

      expect(item.id, '');
      expect(item.obraId, '');
      expect(item.obraTitulo, '');
      expect(item.artistaNombre, '');
      expect(item.precio, 0);
      expect(item.imagenUrl, isNull);
    });
  });

  group('CartItemModel.precioFormateado', () {
    test('formatea el precio con separador de miles y sufijo COP', () {
      const item = CartItemModel(
        id: '1',
        obraId: '1',
        obraTitulo: 'Obra',
        artistaNombre: 'Artista',
        precio: 150000,
      );

      expect(item.precioFormateado, r'$150.000 COP');
    });
  });
}
