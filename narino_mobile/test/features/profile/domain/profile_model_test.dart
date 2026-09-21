import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/profile/domain/profile_model.dart';

void main() {
  group('ProfileModel.fromJson - identificadores', () {
    test('usa slug como id si está presente, sino id', () {
      final withSlug = ProfileModel.fromJson({'slug': 'ana-diaz', 'id': '1'});
      final withoutSlug = ProfileModel.fromJson({'id': '1'});

      expect(withSlug.id, 'ana-diaz');
      expect(withoutSlug.id, '1');
    });

    test('usa user_id como userId si está presente, sino id', () {
      final withUserId =
          ProfileModel.fromJson({'user_id': 'u-1', 'id': '1'});
      final withoutUserId = ProfileModel.fromJson({'id': '1'});

      expect(withUserId.userId, 'u-1');
      expect(withoutUserId.userId, '1');
    });
  });

  group('ProfileModel.fromJson - nombreArtistico', () {
    test('prioriza artistic_name sobre nombre_artistico y first_name', () {
      final model = ProfileModel.fromJson({
        'artistic_name': 'Nombre Artístico',
        'nombre_artistico': 'Otro nombre',
        'first_name': 'Nombre Real',
      });

      expect(model.nombreArtistico, 'Nombre Artístico');
    });

    test('usa nombre_artistico si no viene artistic_name', () {
      final model = ProfileModel.fromJson({
        'nombre_artistico': 'Nombre Local',
        'first_name': 'Nombre Real',
      });

      expect(model.nombreArtistico, 'Nombre Local');
    });

    test('cae a first_name si no vienen artistic_name ni nombre_artistico',
        () {
      final model = ProfileModel.fromJson({'first_name': 'Nombre Real'});

      expect(model.nombreArtistico, 'Nombre Real');
    });

    test('es cadena vacía si no viene ninguna clave', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.nombreArtistico, '');
    });
  });

  group('ProfileModel.fromJson - disciplina', () {
    test('prioriza discipline sobre disciplina', () {
      final model = ProfileModel.fromJson({
        'discipline': 'Pintura',
        'disciplina': 'Escultura',
      });

      expect(model.disciplina, 'Pintura');
    });

    test('usa disciplina si no viene discipline', () {
      final model = ProfileModel.fromJson({'disciplina': 'Escultura'});

      expect(model.disciplina, 'Escultura');
    });

    test('es cadena vacía si no viene ninguna clave', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.disciplina, '');
    });
  });

  group('ProfileModel.fromJson - biografia', () {
    test('prioriza bio sobre biografia', () {
      final model = ProfileModel.fromJson({
        'bio': 'Biografía en inglés',
        'biografia': 'Biografía en español',
      });

      expect(model.biografia, 'Biografía en inglés');
    });

    test('usa biografia si no viene bio', () {
      final model = ProfileModel.fromJson({'biografia': 'Biografía local'});

      expect(model.biografia, 'Biografía local');
    });

    test('es null si no viene ninguna clave', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.biografia, isNull);
    });
  });

  group('ProfileModel.fromJson - fotoUrl', () {
    test('usa avatar_url si está presente', () {
      final model = ProfileModel.fromJson({
        'avatar_url': 'https://cdn.test/avatar.jpg',
        'profile_image_url': 'https://cdn.test/profile.jpg',
        'foto_url': 'https://cdn.test/foto.jpg',
      });

      expect(model.fotoUrl, 'https://cdn.test/avatar.jpg');
    });

    test('cae a profile_image_url si avatar_url no viene', () {
      final model = ProfileModel.fromJson({
        'profile_image_url': 'https://cdn.test/profile.jpg',
        'foto_url': 'https://cdn.test/foto.jpg',
      });

      expect(model.fotoUrl, 'https://cdn.test/profile.jpg');
    });

    test(
        'cae a profile_image_url cuando avatar_url es cadena vacía '
        '(bug corregido: "" se trata como ausente, no como valor válido)', () {
      final model = ProfileModel.fromJson({
        'avatar_url': '',
        'profile_image_url': 'https://cdn.test/profile.jpg',
      });

      expect(model.fotoUrl, 'https://cdn.test/profile.jpg');
    });

    test('cae a foto_url si avatar_url y profile_image_url no vienen', () {
      final model = ProfileModel.fromJson({
        'foto_url': 'https://cdn.test/foto.jpg',
      });

      expect(model.fotoUrl, 'https://cdn.test/foto.jpg');
    });

    test('es null cuando todas las claves de foto son cadena vacía o faltan',
        () {
      final model = ProfileModel.fromJson({
        'avatar_url': '',
        'profile_image_url': '',
        'foto_url': '',
      });

      expect(model.fotoUrl, isNull);
    });

    test('es null cuando no viene ninguna clave de foto', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.fotoUrl, isNull);
    });
  });

  group('ProfileModel.fromJson - contadores', () {
    test('mapea followers_count y following_count', () {
      final model = ProfileModel.fromJson({
        'followers_count': 10,
        'following_count': 5,
      });

      expect(model.seguidores, 10);
      expect(model.siguiendo, 5);
    });

    test('cae a seguidores/siguiendo si no vienen las claves en inglés', () {
      final model = ProfileModel.fromJson({
        'seguidores': 7,
        'siguiendo': 3,
      });

      expect(model.seguidores, 7);
      expect(model.siguiendo, 3);
    });

    test('parsea contadores que llegan como String', () {
      final model = ProfileModel.fromJson({
        'followers_count': '12',
        'following_count': '4',
      });

      expect(model.seguidores, 12);
      expect(model.siguiendo, 4);
    });

    test('son 0 por defecto cuando no vienen', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.seguidores, 0);
      expect(model.siguiendo, 0);
    });

    test('mapea artworks_count y available_artworks', () {
      final model = ProfileModel.fromJson({
        'artworks_count': 8,
        'available_artworks': 6,
      });

      expect(model.totalObras, 8);
      expect(model.obrasDisponibles, 6);
    });

    test('cae a total_obras/obras_disponibles si no vienen en inglés', () {
      final model = ProfileModel.fromJson({
        'total_obras': 9,
        'obras_disponibles': 2,
      });

      expect(model.totalObras, 9);
      expect(model.obrasDisponibles, 2);
    });
  });

  group('ProfileModel.fromJson - esSeguido', () {
    test('usa is_following si está presente', () {
      final model = ProfileModel.fromJson({'is_following': true});

      expect(model.esSeguido, isTrue);
    });

    test('cae a es_seguido si no viene is_following', () {
      final model = ProfileModel.fromJson({'es_seguido': true});

      expect(model.esSeguido, isTrue);
    });

    test('es false por defecto', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.esSeguido, isFalse);
    });
  });

  group('ProfileModel.fromJson - esVerificado', () {
    test('usa is_verified si está presente', () {
      final model = ProfileModel.fromJson({'is_verified': true});

      expect(model.esVerificado, isTrue);
    });

    test('cae a is_public si no viene is_verified', () {
      final model = ProfileModel.fromJson({'is_public': true});

      expect(model.esVerificado, isTrue);
    });

    test('cae a es_verificado si no vienen is_verified ni is_public', () {
      final model = ProfileModel.fromJson({'es_verificado': true});

      expect(model.esVerificado, isTrue);
    });

    test('es false por defecto', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.esVerificado, isFalse);
    });
  });

  group('ProfileModel.fromJson - redesSociales', () {
    test('copia el mapa redes_sociales si viene como tal', () {
      final model = ProfileModel.fromJson({
        'redes_sociales': {'instagram': '@ana'},
      });

      expect(model.redesSociales, {'instagram': '@ana'});
    });

    test('agrega las urls sueltas (website/instagram/facebook/tiktok)', () {
      final model = ProfileModel.fromJson({
        'website_url': 'https://ana.test',
        'instagram_url': 'https://instagram.test/ana',
        'facebook_url': 'https://facebook.test/ana',
        'tiktok_url': 'https://tiktok.test/@ana',
      });

      expect(model.redesSociales, {
        'website': 'https://ana.test',
        'instagram': 'https://instagram.test/ana',
        'facebook': 'https://facebook.test/ana',
        'tiktok': 'https://tiktok.test/@ana',
      });
    });

    test('combina redes_sociales con las urls sueltas', () {
      final model = ProfileModel.fromJson({
        'redes_sociales': {'twitter': '@ana'},
        'website_url': 'https://ana.test',
      });

      expect(model.redesSociales, {
        'twitter': '@ana',
        'website': 'https://ana.test',
      });
    });

    test('es un mapa vacío si no viene ninguna clave', () {
      final model = ProfileModel.fromJson({'id': '1'});

      expect(model.redesSociales, isEmpty);
    });
  });

  group('ArtisticDisciplines', () {
    test('contiene una lista no vacía de disciplinas', () {
      expect(ArtisticDisciplines.all, isNotEmpty);
      expect(ArtisticDisciplines.all, contains('Pintura'));
    });
  });
}
