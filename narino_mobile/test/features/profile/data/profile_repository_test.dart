import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narino_cultura/features/profile/data/profile_repository.dart';
import 'package:narino_cultura/features/profile/data/profile_service.dart';

class _MockProfileService extends Mock implements ProfileService {}

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

Map<String, dynamic> _profileJson({String id = '1'}) => {
      'id': id,
      'artistic_name': 'Artista $id',
      'discipline': 'Pintura',
      'followers_count': 3,
      'following_count': 1,
      'artworks_count': 2,
      'available_artworks': 1,
    };

Map<String, dynamic> _portfolioItemJson({String id = 'item-1'}) => {
      'id': id,
      'tipo': 'imagen',
      'url': 'https://cdn.test/$id.jpg',
      'orden': 0,
    };

void main() {
  late _MockProfileService service;
  late ProfileRepository repo;

  setUpAll(() {
    registerFallbackValue(File('fallback.jpg'));
  });

  setUp(() {
    service = _MockProfileService();
    repo = ProfileRepository(service: service);
  });

  group('getMyProfile', () {
    test('mapea el perfil devuelto por el servicio', () async {
      when(() => service.getMyProfile())
          .thenAnswer((_) async => _profileJson());

      final profile = await repo.getMyProfile();

      expect(profile, isNotNull);
      expect(profile!.nombreArtistico, 'Artista 1');
      expect(profile.disciplina, 'Pintura');
    });

    test('devuelve null cuando el servicio responde 404', () async {
      when(() => service.getMyProfile()).thenThrow(_httpError(404));

      final profile = await repo.getMyProfile();

      expect(profile, isNull);
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getMyProfile()).thenThrow(_connectionError());

      await expectLater(
        repo.getMyProfile(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });

  group('updateMyProfile', () {
    test('mapea el perfil actualizado devuelto por el servicio', () async {
      when(() => service.updateMyProfile(
            nombreArtistico: any(named: 'nombreArtistico'),
            disciplina: any(named: 'disciplina'),
            biografia: any(named: 'biografia'),
            foto: any(named: 'foto'),
            redesSociales: any(named: 'redesSociales'),
            artistId: any(named: 'artistId'),
          )).thenAnswer((_) async => _profileJson(id: '2'));

      final profile = await repo.updateMyProfile(nombreArtistico: 'Artista 2');

      expect(profile.nombreArtistico, 'Artista 2');
    });

    test('traduce un 400 con detalle de campo a su mensaje', () async {
      when(() => service.updateMyProfile(
            nombreArtistico: any(named: 'nombreArtistico'),
            disciplina: any(named: 'disciplina'),
            biografia: any(named: 'biografia'),
            foto: any(named: 'foto'),
            redesSociales: any(named: 'redesSociales'),
            artistId: any(named: 'artistId'),
          )).thenThrow(_httpError(400, data: {
            'discipline': ['Este campo es requerido.'],
          }));

      await expectLater(
        repo.updateMyProfile(disciplina: ''),
        throwsA('Este campo es requerido.'),
      );
    });
  });

  group('getProfileById', () {
    test('mapea el perfil del artista solicitado', () async {
      when(() => service.getProfileById('ana-diaz'))
          .thenAnswer((_) async => _profileJson(id: '3'));

      final profile = await repo.getProfileById('ana-diaz');

      expect(profile.nombreArtistico, 'Artista 3');
    });

    test('traduce un 404 a un mensaje entendible', () async {
      when(() => service.getProfileById('inexistente'))
          .thenThrow(_httpError(404));

      await expectLater(
        repo.getProfileById('inexistente'),
        throwsA('Recurso no encontrado.'),
      );
    });
  });

  group('getPortfolio', () {
    test('mapea y ordena los elementos del portafolio', () async {
      when(() => service.getPortfolio('ana-diaz')).thenAnswer((_) async => [
            {..._portfolioItemJson(id: 'item-2'), 'orden': 2},
            {..._portfolioItemJson(id: 'item-1'), 'orden': 1},
          ]);

      final result = await repo.getPortfolio('ana-diaz');

      expect(result, hasLength(2));
      expect(result.first.id, 'item-1');
      expect(result.last.id, 'item-2');
    });

    test(
        'devuelve lista vacía cuando el servicio ya normalizó un 404 '
        '(ProfileService.getPortfolio captura el 404 y devuelve [])',
        () async {
      when(() => service.getPortfolio('sin-portafolio'))
          .thenAnswer((_) async => []);

      final result = await repo.getPortfolio('sin-portafolio');

      expect(result, isEmpty);
    });

    test('traduce un error inesperado propagado por el servicio', () async {
      when(() => service.getPortfolio('ana-diaz'))
          .thenThrow(_httpError(403));

      await expectLater(
        repo.getPortfolio('ana-diaz'),
        throwsA('No tienes permiso para realizar esta acción.'),
      );
    });
  });

  group('addPortfolioItem', () {
    test('mapea el elemento de portafolio creado', () async {
      when(() => service.addPortfolioItem(
            profileId: any(named: 'profileId'),
            file: any(named: 'file'),
            tipo: any(named: 'tipo'),
            titulo: any(named: 'titulo'),
            descripcion: any(named: 'descripcion'),
          )).thenAnswer((_) async => _portfolioItemJson());

      final result = await repo.addPortfolioItem(
        profileId: 'ana-diaz',
        file: File('test.jpg'),
        tipo: 'imagen',
      );

      expect(result.id, 'item-1');
      expect(result.tipo, 'imagen');
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.addPortfolioItem(
            profileId: any(named: 'profileId'),
            file: any(named: 'file'),
            tipo: any(named: 'tipo'),
            titulo: any(named: 'titulo'),
            descripcion: any(named: 'descripcion'),
          )).thenThrow(_connectionError());

      await expectLater(
        repo.addPortfolioItem(
          profileId: 'ana-diaz',
          file: File('test.jpg'),
          tipo: 'imagen',
        ),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });

  group('followArtist', () {
    test('mapea el perfil devuelto tras seguir al artista', () async {
      when(() => service.followArtist('ana-diaz')).thenAnswer(
          (_) async => {..._profileJson(), 'is_following': true});

      final result = await repo.followArtist('ana-diaz');

      expect(result.esSeguido, isTrue);
    });

    test('traduce un 401 a un mensaje entendible', () async {
      when(() => service.followArtist('ana-diaz')).thenThrow(_httpError(401));

      await expectLater(
        repo.followArtist('ana-diaz'),
        throwsA('Tu sesión expiró. Inicia sesión nuevamente.'),
      );
    });
  });

  group('unfollowArtist', () {
    test('mapea el perfil devuelto tras dejar de seguir al artista',
        () async {
      when(() => service.unfollowArtist('ana-diaz')).thenAnswer(
          (_) async => {..._profileJson(), 'is_following': false});

      final result = await repo.unfollowArtist('ana-diaz');

      expect(result.esSeguido, isFalse);
    });

    test('traduce un error inesperado a un mensaje genérico', () async {
      when(() => service.unfollowArtist('ana-diaz'))
          .thenThrow(_httpError(500));

      await expectLater(
        repo.unfollowArtist('ana-diaz'),
        throwsA('Error inesperado. Intenta de nuevo.'),
      );
    });
  });

  group('getMyFollowing', () {
    test('mapea la lista de perfiles seguidos', () async {
      when(() => service.getMyFollowing()).thenAnswer((_) async => [
            _profileJson(id: '1'),
            _profileJson(id: '2'),
          ]);

      final result = await repo.getMyFollowing();

      expect(result, hasLength(2));
      expect(result.first.nombreArtistico, 'Artista 1');
    });

    test(
        'devuelve lista vacía cuando el servicio ya normalizó un 404 '
        '(ProfileService.getMyFollowing captura el 404 y devuelve [])',
        () async {
      when(() => service.getMyFollowing()).thenAnswer((_) async => []);

      final result = await repo.getMyFollowing();

      expect(result, isEmpty);
    });

    test('traduce un error de conexión a un mensaje entendible', () async {
      when(() => service.getMyFollowing()).thenThrow(_connectionError());

      await expectLater(
        repo.getMyFollowing(),
        throwsA('No se pudo conectar al servidor.'),
      );
    });
  });
}
