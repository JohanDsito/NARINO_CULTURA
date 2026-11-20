import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/musicians/domain/musician_model.dart';

void main() {
  group('MusicGenreModel.fromJson', () {
    test('parsea los campos básicos', () {
      final model = MusicGenreModel.fromJson({
        'id': 4,
        'name': 'Andina',
        'slug': 'andina',
      });

      expect(model.id, 4);
      expect(model.name, 'Andina');
      expect(model.slug, 'andina');
    });

    test('usa "nombre" como respaldo cuando falta "name"', () {
      final model = MusicGenreModel.fromJson({'id': 1, 'nombre': 'Bambuco'});

      expect(model.name, 'Bambuco');
    });

    test('usa cadenas vacías cuando faltan name/slug', () {
      final model = MusicGenreModel.fromJson({'id': 2});

      expect(model.name, '');
      expect(model.slug, '');
    });
  });

  group('MusicalWorkModel.fromJson', () {
    test('lee audio_file y thumbnail del backend (no audio_url/cover_url)',
        () {
      final work = MusicalWorkModel.fromJson({
        'id': 10,
        'title': 'Canción de prueba',
        'audio_file': 'https://cdn.test/audio.mp3',
        'thumbnail': 'https://cdn.test/cover.jpg',
        'created_at': '2025-05-01T00:00:00.000Z',
      });

      expect(work.audioUrl, 'https://cdn.test/audio.mp3');
      expect(work.coverUrl, 'https://cdn.test/cover.jpg');
    });

    test('usa audio_url/cover_url como respaldo si no vienen audio_file/thumbnail',
        () {
      final work = MusicalWorkModel.fromJson({
        'id': 11,
        'title': 'Otra canción',
        'audio_url': 'https://cdn.test/fallback-audio.mp3',
        'cover_url': 'https://cdn.test/fallback-cover.jpg',
        'created_at': '2025-05-01T00:00:00.000Z',
      });

      expect(work.audioUrl, 'https://cdn.test/fallback-audio.mp3');
      expect(work.coverUrl, 'https://cdn.test/fallback-cover.jpg');
    });

    test('prefiere audio_file/thumbnail sobre audio_url/cover_url si ambos vienen',
        () {
      final work = MusicalWorkModel.fromJson({
        'id': 12,
        'title': 'Preferencia',
        'audio_file': 'https://cdn.test/preferido.mp3',
        'audio_url': 'https://cdn.test/no-preferido.mp3',
        'thumbnail': 'https://cdn.test/preferido.jpg',
        'cover_url': 'https://cdn.test/no-preferido.jpg',
        'created_at': '2025-05-01T00:00:00.000Z',
      });

      expect(work.audioUrl, 'https://cdn.test/preferido.mp3');
      expect(work.coverUrl, 'https://cdn.test/preferido.jpg');
    });

    test('usa "titulo" como respaldo cuando falta "title"', () {
      final work = MusicalWorkModel.fromJson({
        'id': 13,
        'titulo': 'Título en español',
        'created_at': '2025-05-01T00:00:00.000Z',
      });

      expect(work.title, 'Título en español');
    });

    test('parsea year, genre, work_type y duration_seconds', () {
      final work = MusicalWorkModel.fromJson({
        'id': 14,
        'title': 'Con metadatos',
        'year': 2020,
        'genre': 'Salsa',
        'work_type': 'cancion',
        'duration_seconds': '215',
        'created_at': '2025-05-01T00:00:00.000Z',
      });

      expect(work.year, 2020);
      expect(work.genre, 'Salsa');
      expect(work.workType, 'cancion');
      expect(work.durationSeconds, 215);
    });

    test('usa la fecha actual cuando created_at falta o es inválida', () {
      final before = DateTime.now();
      final work = MusicalWorkModel.fromJson({
        'id': 15,
        'title': 'Sin fecha',
      });
      final after = DateTime.now();

      expect(
        work.createdAt.isAfter(before.subtract(const Duration(seconds: 5))),
        isTrue,
      );
      expect(
        work.createdAt.isBefore(after.add(const Duration(seconds: 5))),
        isTrue,
      );
    });
  });

  group('MusicianReviewModel.fromJson', () {
    test('lee nombre y avatar desde un mapa "reviewer"', () {
      final review = MusicianReviewModel.fromJson({
        'id': 1,
        'reviewer': {
          'name': 'Carlos Ruiz',
          'avatar_url': 'https://cdn.test/avatar.jpg',
        },
        'rating': 5,
        'comment': 'Excelente',
        'created_at': '2025-06-01T00:00:00.000Z',
      });

      expect(review.reviewerName, 'Carlos Ruiz');
      expect(review.reviewerAvatar, 'https://cdn.test/avatar.jpg');
      expect(review.rating, 5);
      expect(review.comment, 'Excelente');
    });

    test('usa username o email si el reviewer no tiene name', () {
      final review = MusicianReviewModel.fromJson({
        'id': 2,
        'reviewer': {'username': 'carlosr'},
        'rating': 4,
        'created_at': '2025-06-01T00:00:00.000Z',
      });

      expect(review.reviewerName, 'carlosr');
    });

    test('usa reviewer_name/reviewer_avatar cuando "reviewer" no es un mapa',
        () {
      final review = MusicianReviewModel.fromJson({
        'id': 3,
        'reviewer_name': 'Ana López',
        'reviewer_avatar': 'https://cdn.test/ana.jpg',
        'rating': 3,
        'created_at': '2025-06-01T00:00:00.000Z',
      });

      expect(review.reviewerName, 'Ana López');
      expect(review.reviewerAvatar, 'https://cdn.test/ana.jpg');
    });

    test('usa "comentario" como respaldo cuando falta "comment"', () {
      final review = MusicianReviewModel.fromJson({
        'id': 4,
        'rating': 2,
        'comentario': 'Regular',
        'created_at': '2025-06-01T00:00:00.000Z',
      });

      expect(review.comment, 'Regular');
    });
  });

  group('MusicianModel.fromJson', () {
    Map<String, dynamic> baseJson() => {
          'slug': 'los-andinos',
          'artistic_name': 'Los Andinos',
          'bio': 'Agrupación de música andina',
          'city': 'Pasto',
          'profile_image_url': 'https://cdn.test/foto.jpg',
          'genres': [
            {'name': 'Andina'},
            {'name': 'Bambuco'},
          ],
          'aggregation_type': 'banda',
          'is_following': true,
          'followers_count': 120,
          'average_rating': '4.5',
          'reviews_count': 8,
          'is_verified': true,
        };

    test('lee "artistic_name" como el nombre del músico', () {
      final musician = MusicianModel.fromJson(baseJson());

      expect(musician.name, 'Los Andinos');
    });

    test('usa "name" como respaldo cuando no viene artistic_name', () {
      final json = {...baseJson()}..remove('artistic_name');
      json['name'] = 'Nombre alterno';

      final musician = MusicianModel.fromJson(json);

      expect(musician.name, 'Nombre alterno');
    });

    test('lee fotoUrl/photoUrl desde profile_image_url', () {
      final musician = MusicianModel.fromJson(baseJson());

      expect(musician.photoUrl, 'https://cdn.test/foto.jpg');
    });

    test('trata profile_image_url vacío ("") como null', () {
      final json = {...baseJson(), 'profile_image_url': ''};

      final musician = MusicianModel.fromJson(json);

      expect(musician.photoUrl, isNull);
    });

    test('photoUrl es null cuando profile_image_url no viene en el json', () {
      final json = {...baseJson()}..remove('profile_image_url');

      final musician = MusicianModel.fromJson(json);

      expect(musician.photoUrl, isNull);
    });

    test('mapea la lista de géneros desde objetos con "name"', () {
      final musician = MusicianModel.fromJson(baseJson());

      expect(musician.genres, ['Andina', 'Bambuco']);
    });

    test('mapea la lista de géneros cuando vienen como strings', () {
      final json = {
        ...baseJson(),
        'genres': ['Salsa', 'Merengue'],
      };

      final musician = MusicianModel.fromJson(json);

      expect(musician.genres, ['Salsa', 'Merengue']);
    });

    test('usa cadenas vacías/valores por defecto cuando faltan campos', () {
      final musician = MusicianModel.fromJson({'slug': 'sin-datos'});

      expect(musician.name, '');
      expect(musician.bio, isNull);
      expect(musician.city, isNull);
      expect(musician.photoUrl, isNull);
      expect(musician.genres, isEmpty);
      expect(musician.isFollowing, isFalse);
      expect(musician.followersCount, 0);
      expect(musician.averageRating, 0.0);
      expect(musician.reviewsCount, 0);
      expect(musician.isVerified, isFalse);
    });

    test('parsea followers_count, average_rating y reviews_count', () {
      final musician = MusicianModel.fromJson(baseJson());

      expect(musician.followersCount, 120);
      expect(musician.averageRating, 4.5);
      expect(musician.reviewsCount, 8);
    });
  });

  group('MusicianModel.copyWith', () {
    test('solo cambia isFollowing y followersCount y preserva el resto', () {
      const original = MusicianModel(
        slug: 'mi-slug',
        name: 'Nombre',
        bio: 'Bio',
        city: 'Pasto',
        photoUrl: 'https://cdn.test/foto.jpg',
        coverUrl: null,
        genres: ['Andina'],
        aggregationType: 'solista',
        isFollowing: false,
        followersCount: 10,
        averageRating: 4.0,
        reviewsCount: 2,
        isVerified: true,
      );

      final updated = original.copyWith(isFollowing: true, followersCount: 11);

      expect(updated.isFollowing, isTrue);
      expect(updated.followersCount, 11);
      expect(updated.name, 'Nombre');
      expect(updated.bio, 'Bio');
      expect(updated.genres, ['Andina']);
      expect(updated.isVerified, isTrue);
    });
  });
}
