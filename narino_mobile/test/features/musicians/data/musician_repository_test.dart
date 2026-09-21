import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/musicians/data/musician_repository.dart';
import 'package:narino_cultura/features/musicians/data/musician_service.dart';

class _MockMusicianService extends Mock implements MusicianService {}

/// Construye un [DioException] como el que lanzaría Dio ante una respuesta
/// HTTP con [statusCode], para probar el manejo de errores del repositorio.
DioException _httpError(int statusCode, {Object? data}) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

DioException _connectionError() => DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );

Map<String, dynamic> _musicianJson({String slug = 'los-andinos'}) => {
      'slug': slug,
      'artistic_name': 'Los Andinos',
      'city': 'Pasto',
      'profile_image_url': 'https://cdn.test/foto.jpg',
      'genres': ['Andina'],
      'is_following': false,
      'followers_count': 10,
      'average_rating': '4.5',
      'reviews_count': 3,
      'is_verified': false,
    };

Map<String, dynamic> _workJson({int id = 1}) => {
      'id': id,
      'title': 'Canción $id',
      'audio_file': 'https://cdn.test/audio.mp3',
      'thumbnail': 'https://cdn.test/cover.jpg',
      'created_at': '2025-01-01T00:00:00.000Z',
    };

void main() {
  late _MockMusicianService service;
  late MusicianRepository repo;

  setUp(() {
    service = _MockMusicianService();
    repo = MusicianRepository(service: service);
  });

  group('getMusicians', () {
    test('mapea la lista de resultados', () async {
      when(() => service.getMusicians(
            search: any(named: 'search'),
            genre: any(named: 'genre'),
            city: any(named: 'city'),
            aggregationType: any(named: 'aggregationType'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => {
            'results': [
              _musicianJson(slug: 'a'),
              _musicianJson(slug: 'b'),
            ],
            'count': 2,
          });

      final result = await repo.getMusicians();

      expect(result, hasLength(2));
      expect(result.first.slug, 'a');
      expect(result.first.name, 'Los Andinos');
    });

    test('devuelve lista vacía si "results" no es una lista', () async {
      when(() => service.getMusicians(
            search: any(named: 'search'),
            genre: any(named: 'genre'),
            city: any(named: 'city'),
            aggregationType: any(named: 'aggregationType'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => {'count': 0});

      final result = await repo.getMusicians();

      expect(result, isEmpty);
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getMusicians(
            search: any(named: 'search'),
            genre: any(named: 'genre'),
            city: any(named: 'city'),
            aggregationType: any(named: 'aggregationType'),
            page: any(named: 'page'),
          )).thenThrow(_connectionError());

      await expectLater(
        repo.getMusicians(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });

    test('extrae el primer mensaje de error de un 400 con detalle de campo',
        () async {
      when(() => service.getMusicians(
            search: any(named: 'search'),
            genre: any(named: 'genre'),
            city: any(named: 'city'),
            aggregationType: any(named: 'aggregationType'),
            page: any(named: 'page'),
          )).thenThrow(_httpError(400, data: {
            'city': ['Este campo es requerido.'],
          }));

      await expectLater(
        repo.getMusicians(),
        throwsA('Este campo es requerido.'),
      );
    });
  });

  group('getMusicianDetail', () {
    test('mapea el detalle del músico', () async {
      when(() => service.getMusicianDetail('los-andinos'))
          .thenAnswer((_) async => _musicianJson());

      final musician = await repo.getMusicianDetail('los-andinos');

      expect(musician.slug, 'los-andinos');
      expect(musician.name, 'Los Andinos');
    });

    test('traduce un 404 a "Músico no encontrado."', () async {
      when(() => service.getMusicianDetail('no-existe'))
          .thenThrow(_httpError(404));

      await expectLater(
        repo.getMusicianDetail('no-existe'),
        throwsA('Músico no encontrado.'),
      );
    });
  });

  group('toggleFollow', () {
    test('devuelve el booleano que retorna el servicio', () async {
      when(() => service.toggleFollow('los-andinos'))
          .thenAnswer((_) async => true);

      final result = await repo.toggleFollow('los-andinos');

      expect(result, isTrue);
    });

    test('traduce un 401 a un mensaje de sesión expirada', () async {
      when(() => service.toggleFollow('los-andinos'))
          .thenThrow(_httpError(401));

      await expectLater(
        repo.toggleFollow('los-andinos'),
        throwsA('Tu sesión expiró. Inicia sesión nuevamente.'),
      );
    });
  });

  group('getGenres', () {
    test('mapea la lista de géneros', () async {
      when(() => service.getGenres()).thenAnswer((_) async => [
            {'id': 1, 'name': 'Andina', 'slug': 'andina'},
            {'id': 2, 'name': 'Bambuco', 'slug': 'bambuco'},
          ]);

      final genres = await repo.getGenres();

      expect(genres, hasLength(2));
      expect(genres.first.name, 'Andina');
    });

    test('traduce un 403 a un mensaje entendible', () async {
      when(() => service.getGenres()).thenThrow(_httpError(403));

      await expectLater(
        repo.getGenres(),
        throwsA('No tienes permiso para realizar esta acción.'),
      );
    });
  });

  group('getMyProfile', () {
    test('mapea el perfil cuando el servicio lo encuentra', () async {
      when(() => service.getMyProfile())
          .thenAnswer((_) async => _musicianJson());

      final musician = await repo.getMyProfile();

      expect(musician, isNotNull);
      expect(musician!.slug, 'los-andinos');
    });

    test('devuelve null cuando el servicio no encuentra perfil (404)',
        () async {
      when(() => service.getMyProfile()).thenAnswer((_) async => null);

      final musician = await repo.getMyProfile();

      expect(musician, isNull);
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getMyProfile()).thenThrow(_connectionError());

      await expectLater(
        repo.getMyProfile(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });

  group('saveMyProfile', () {
    test('llama al servicio con existingSlug cuando se está actualizando',
        () async {
      when(() => service.saveMyProfile(
            artisticName: any(named: 'artisticName'),
            aggregationType: any(named: 'aggregationType'),
            genreIds: any(named: 'genreIds'),
            existingSlug: any(named: 'existingSlug'),
          )).thenAnswer((_) async => _musicianJson());

      final musician = await repo.saveMyProfile(
        artisticName: 'Los Andinos',
        aggregationType: 'banda',
        genreIds: [1, 2],
        existingSlug: 'los-andinos',
      );

      verify(() => service.saveMyProfile(
            artisticName: 'Los Andinos',
            aggregationType: 'banda',
            genreIds: [1, 2],
            existingSlug: 'los-andinos',
          )).called(1);
      expect(musician.slug, 'los-andinos');
    });

    test('llama al servicio sin existingSlug cuando se está creando',
        () async {
      when(() => service.saveMyProfile(
            artisticName: any(named: 'artisticName'),
            aggregationType: any(named: 'aggregationType'),
            genreIds: any(named: 'genreIds'),
            existingSlug: any(named: 'existingSlug'),
          )).thenAnswer((_) async => _musicianJson(slug: 'nuevo-musico'));

      final musician = await repo.saveMyProfile(
        artisticName: 'Nuevo Músico',
        aggregationType: 'solista',
        genreIds: null,
        existingSlug: null,
      );

      verify(() => service.saveMyProfile(
            artisticName: 'Nuevo Músico',
            aggregationType: 'solista',
            genreIds: null,
            existingSlug: null,
          )).called(1);
      expect(musician.slug, 'nuevo-musico');
    });

    test('extrae el primer mensaje de error de un 400 con detalle de campo',
        () async {
      when(() => service.saveMyProfile(
            artisticName: any(named: 'artisticName'),
            aggregationType: any(named: 'aggregationType'),
            genreIds: any(named: 'genreIds'),
            existingSlug: any(named: 'existingSlug'),
          )).thenThrow(_httpError(400, data: {
            'artistic_name': ['Este campo es requerido.'],
          }));

      await expectLater(
        repo.saveMyProfile(artisticName: ''),
        throwsA('Este campo es requerido.'),
      );
    });
  });

  group('addWork', () {
    test('mapea la obra creada', () async {
      when(() => service.addWork('los-andinos', any()))
          .thenAnswer((_) async => _workJson());

      final work = await repo.addWork('los-andinos', {'title': 'Canción 1'});

      expect(work.id, 1);
      expect(work.audioUrl, 'https://cdn.test/audio.mp3');
      expect(work.coverUrl, 'https://cdn.test/cover.jpg');
    });

    test('traduce un 404 a "Músico no encontrado."', () async {
      when(() => service.addWork('no-existe', any()))
          .thenThrow(_httpError(404));

      await expectLater(
        repo.addWork('no-existe', {'title': 'Canción 1'}),
        throwsA('Músico no encontrado.'),
      );
    });

    test('devuelve el mensaje inesperado por defecto cuando no hay detalle',
        () async {
      when(() => service.addWork('los-andinos', any()))
          .thenThrow(_httpError(500, data: {}));

      await expectLater(
        repo.addWork('los-andinos', {'title': 'Canción 1'}),
        throwsA('Error inesperado. Intenta de nuevo.'),
      );
    });
  });
}
