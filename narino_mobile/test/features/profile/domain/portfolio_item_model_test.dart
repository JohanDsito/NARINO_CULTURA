import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/profile/domain/portfolio_item_model.dart';

void main() {
  group('PortfolioItemModel.fromJson', () {
    test('mapea todos los campos básicos', () {
      final item = PortfolioItemModel.fromJson({
        'id': 'item-1',
        'tipo': 'video',
        'url': 'https://cdn.test/video.mp4',
        'titulo': 'Mi obra',
        'descripcion': 'Descripción de la obra',
        'orden': 3,
      });

      expect(item.id, 'item-1');
      expect(item.tipo, 'video');
      expect(item.url, 'https://cdn.test/video.mp4');
      expect(item.titulo, 'Mi obra');
      expect(item.descripcion, 'Descripción de la obra');
      expect(item.orden, 3);
    });

    test('usa "imagen" como tipo por defecto cuando no viene', () {
      final item = PortfolioItemModel.fromJson({'id': '1'});

      expect(item.tipo, 'imagen');
    });

    test('usa cadenas vacías cuando faltan id/url', () {
      final item = PortfolioItemModel.fromJson({});

      expect(item.id, '');
      expect(item.url, '');
    });

    test('titulo y descripcion son null cuando no vienen', () {
      final item = PortfolioItemModel.fromJson({'id': '1'});

      expect(item.titulo, isNull);
      expect(item.descripcion, isNull);
    });

    test('orden es 0 por defecto cuando no viene', () {
      final item = PortfolioItemModel.fromJson({'id': '1'});

      expect(item.orden, 0);
    });
  });

  group('PortfolioItemModel.isImage / isVideo', () {
    test('isImage es true solo cuando tipo es "imagen"', () {
      final imagen =
          PortfolioItemModel.fromJson({'id': '1', 'tipo': 'imagen'});
      final video = PortfolioItemModel.fromJson({'id': '2', 'tipo': 'video'});

      expect(imagen.isImage, isTrue);
      expect(video.isImage, isFalse);
    });

    test('isVideo es true solo cuando tipo es "video"', () {
      final imagen =
          PortfolioItemModel.fromJson({'id': '1', 'tipo': 'imagen'});
      final video = PortfolioItemModel.fromJson({'id': '2', 'tipo': 'video'});

      expect(video.isVideo, isTrue);
      expect(imagen.isVideo, isFalse);
    });
  });
}
