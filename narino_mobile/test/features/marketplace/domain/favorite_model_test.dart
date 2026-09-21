import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/marketplace/domain/favorite_model.dart';

void main() {
  group('FavoriteModel.fromJson', () {
    test('mapea los campos primarios en inglés del backend', () {
      final fav = FavoriteModel.fromJson({
        'id': '5',
        'artwork_id': 'obra-1',
        'artwork_title': 'Barniz de Pasto',
        'artista_nombre': 'Ana Díaz',
        'status': 'DISPONIBLE',
        'price': '150000',
        'main_image_url': 'https://cdn.test/main.jpg',
      });

      expect(fav.id, '5');
      expect(fav.obraId, 'obra-1');
      expect(fav.obraTitulo, 'Barniz de Pasto');
      expect(fav.artistaNombre, 'Ana Díaz');
      expect(fav.estado, 'disponible');
      expect(fav.precio, 150000);
      expect(fav.imagenUrl, 'https://cdn.test/main.jpg');
    });

    test('usa los campos de respaldo cuando faltan los primarios', () {
      final fav = FavoriteModel.fromJson({
        'id': '5',
        'artwork': 'obra-2',
        'title': 'Tamo',
        'estado': 'vendida',
        'precio': '80000',
        'imagen_url': 'https://cdn.test/fallback.jpg',
      });

      expect(fav.obraId, 'obra-2');
      expect(fav.obraTitulo, 'Tamo');
      expect(fav.estado, 'vendida');
      expect(fav.precio, 80000);
      expect(fav.imagenUrl, 'https://cdn.test/fallback.jpg');
    });

    test('usa el segundo nivel de respaldo obra_id/obra_titulo', () {
      final fav = FavoriteModel.fromJson({
        'id': '5',
        'obra_id': 'obra-3',
        'obra_titulo': 'Escultura',
      });

      expect(fav.obraId, 'obra-3');
      expect(fav.obraTitulo, 'Escultura');
    });

    test('usa cadenas vacías y estado disponible por defecto', () {
      final fav = FavoriteModel.fromJson({});

      expect(fav.id, '');
      expect(fav.obraId, '');
      expect(fav.obraTitulo, '');
      expect(fav.artistaNombre, '');
      expect(fav.estado, 'disponible');
      expect(fav.precio, isNull);
      expect(fav.imagenUrl, isNull);
    });
  });

  group('FavoriteModel getters de estado', () {
    FavoriteModel favWithEstado(String estado) => FavoriteModel(
          id: '1',
          obraId: '1',
          obraTitulo: '',
          artistaNombre: '',
          estado: estado,
        );

    test('isDisponible es true solo cuando estado es disponible', () {
      expect(favWithEstado('disponible').isDisponible, isTrue);
      expect(favWithEstado('vendida').isDisponible, isFalse);
    });

    test('isVendida es true solo cuando estado es vendida', () {
      expect(favWithEstado('vendida').isVendida, isTrue);
      expect(favWithEstado('disponible').isVendida, isFalse);
    });

    test('isEnSubasta es true solo cuando estado es en_subasta', () {
      expect(favWithEstado('en_subasta').isEnSubasta, isTrue);
      expect(favWithEstado('disponible').isEnSubasta, isFalse);
    });
  });
}
