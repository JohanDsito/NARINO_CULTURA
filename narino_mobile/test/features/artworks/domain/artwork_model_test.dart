import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';

void main() {
  group('CategoryModel.fromJson', () {
    test('parsea los campos básicos', () {
      final model = CategoryModel.fromJson({
        'id': 3,
        'name': 'Pintura',
        'slug': 'pintura',
      });

      expect(model.id, 3);
      expect(model.name, 'Pintura');
      expect(model.slug, 'pintura');
    });

    test('usa cadenas vacías cuando faltan name/slug', () {
      final model = CategoryModel.fromJson({'id': 1});

      expect(model.name, '');
      expect(model.slug, '');
    });
  });

  group('ArtworkModel.fromJson', () {
    Map<String, dynamic> baseJson() => {
          'id': 'abc-123',
          'title': 'Barniz de Pasto',
          'description': 'Una obra tradicional',
          'category': '2',
          'status': 'available',
          'price': '150000',
          'views_count': 42,
          'artist': 'artist-uuid',
          'artist_slug': 'ana-diaz',
          'artista_nombre': 'Ana Díaz',
          'created_at': '2025-03-01T12:00:00.000Z',
          'images': [
            {'image_url': 'https://cdn.test/1.jpg'},
            {'image_url': 'https://cdn.test/2.jpg'},
          ],
        };

    test('mapea los campos en inglés del backend a los del modelo', () {
      final artwork = ArtworkModel.fromJson(baseJson());

      expect(artwork.id, 'abc-123');
      expect(artwork.titulo, 'Barniz de Pasto');
      expect(artwork.descripcion, 'Una obra tradicional');
      expect(artwork.precio, 150000);
      expect(artwork.artistaId, 'artist-uuid');
      expect(artwork.artistaSlug, 'ana-diaz');
      expect(artwork.artistaNombre, 'Ana Díaz');
      expect(artwork.viewsCount, 42);
      expect(artwork.imagenes, [
        'https://cdn.test/1.jpg',
        'https://cdn.test/2.jpg',
      ]);
    });

    test('normaliza estados en inglés/español a los tres valores internos',
        () {
      expect(ArtworkModel.fromJson({...baseJson(), 'status': 'in_auction'})
          .estado, 'en_subasta');
      expect(
          ArtworkModel.fromJson({...baseJson(), 'status': 'sold'}).estado,
          'vendida');
      expect(
          ArtworkModel.fromJson({...baseJson(), 'status': 'published'})
              .estado,
          'disponible');
      expect(ArtworkModel.fromJson({...baseJson(), 'status': ''}).estado,
          'disponible');
    });

    test('antepone main_image_url si no es ya la primera imagen', () {
      final json = {
        ...baseJson(),
        'main_image_url': 'https://cdn.test/main.jpg',
      };

      final artwork = ArtworkModel.fromJson(json);

      expect(artwork.imagenes.first, 'https://cdn.test/main.jpg');
      expect(artwork.imagenes.length, 3);
    });

    test('deriva el nombre del artista desde el slug si no viene explícito',
        () {
      final json = {
        ...baseJson(),
        'artista_nombre': null,
        'artist_slug': 'juan-perez',
      }..remove('artista_nombre');

      final artwork = ArtworkModel.fromJson(json);

      expect(artwork.artistaNombre, 'Juan Perez');
    });

    test('precio es null cuando el backend no envía price', () {
      final json = {...baseJson()}..remove('price');

      final artwork = ArtworkModel.fromJson(json);

      expect(artwork.precio, isNull);
    });

    test('viewsCount es 0 cuando el backend no envía views_count', () {
      final json = {...baseJson()}..remove('views_count');

      final artwork = ArtworkModel.fromJson(json);

      expect(artwork.viewsCount, 0);
    });
  });

  group('ArtworkModel.copyWith', () {
    test('solo cambia esFavorito y preserva el resto de los campos', () {
      final original = ArtworkModel(
        id: '1',
        titulo: 'Obra',
        descripcion: '',
        categoria: 'Pintura',
        estado: 'disponible',
        imagenes: const [],
        artistaId: 'a1',
        artistaNombre: 'Artista',
        viewsCount: 10,
        esFavorito: false,
        creadoEn: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(esFavorito: true);

      expect(updated.esFavorito, isTrue);
      expect(updated.viewsCount, 10);
      expect(updated.titulo, 'Obra');
    });
  });

  group('ArtworkModel.isDisponible', () {
    test('es true solo cuando estado es "disponible"', () {
      final disponible = ArtworkModel(
        id: '1',
        titulo: '',
        descripcion: '',
        categoria: '',
        estado: 'disponible',
        imagenes: const [],
        artistaId: '',
        artistaNombre: '',
        viewsCount: 0,
        esFavorito: false,
        creadoEn: DateTime(2025, 1, 1),
      );
      final vendida = ArtworkModel(
        id: '1',
        titulo: '',
        descripcion: '',
        categoria: '',
        estado: 'vendida',
        imagenes: const [],
        artistaId: '',
        artistaNombre: '',
        viewsCount: 0,
        esFavorito: false,
        creadoEn: DateTime(2025, 1, 1),
      );

      expect(disponible.isDisponible, isTrue);
      expect(vendida.isDisponible, isFalse);
    });
  });
}
