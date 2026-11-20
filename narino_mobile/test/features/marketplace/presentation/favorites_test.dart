import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/api_error.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_repository.dart';
import 'package:narino_cultura/features/marketplace/domain/favorite_model.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/cart_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/favorites_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/favorites_screen.dart';

const _condor = FavoriteModel(
  id: 'f1',
  obraId: 'o1',
  obraTitulo: 'Cóndor Andino',
  artistaNombre: 'María Torres',
  estado: 'disponible',
  precio: 320000,
);

/// Repositorio en memoria: cuenta llamadas y deja controlar cuándo responde.
class _Repo extends MarketplaceRepository {
  List<FavoriteModel> server = [];
  int gets = 0;
  int adds = 0;
  Object? failWith;
  Completer<void>? gate;

  @override
  Future<List<FavoriteModel>> getFavorites() async {
    gets++;
    if (failWith != null) throw failWith!;
    return [...server];
  }

  @override
  Future<void> addFavorite(String obraId) async {
    adds++;
    await gate?.future;
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> removeFavorite(String obraId) async {
    await gate?.future;
    if (failWith != null) throw failWith!;
  }
}

void main() {
  late _Repo repo;
  late FavoritesNotifier notifier;

  setUp(() {
    repo = _Repo();
    notifier = FavoritesNotifier(repo);
  });

  group('FavoritesNotifier (#76, MO-CONN-02, MO-LOAD-02)', () {
    test('el corazón cambia al instante, antes de que responda el servidor',
        () async {
      await notifier.loadFavorites();
      repo.gate = Completer();

      final pending = notifier.toggleFavorite('o1', favorito: _condor);
      expect(notifier.state.isFavorite('o1'), isTrue);

      repo.gate!.complete();
      await pending;
      expect(notifier.state.isFavorite('o1'), isTrue);
      expect(notifier.state.favorites.single.obraTitulo, 'Cóndor Andino');
    });

    test('con los datos de la obra no vuelve a pedir toda la lista', () async {
      await notifier.loadFavorites();
      final getsAntes = repo.gets;

      await notifier.toggleFavorite('o1', favorito: _condor);

      expect(repo.gets, getsAntes);
    });

    test('toques rápidos sobre la misma obra mandan una sola petición',
        () async {
      await notifier.loadFavorites();
      repo.gate = Completer();

      final first = notifier.toggleFavorite('o1', favorito: _condor);
      for (var i = 0; i < 4; i++) {
        await notifier.toggleFavorite('o1', favorito: _condor);
      }
      repo.gate!.complete();
      await first;

      expect(repo.adds, 1);
      expect(notifier.state.isFavorite('o1'), isTrue);
    });

    test('si el servidor falla, revierte el corazón y deja el motivo', () async {
      await notifier.loadFavorites();
      repo.failWith = ApiError.sinConexion;

      await notifier.toggleFavorite('o1', favorito: _condor);

      expect(notifier.state.isFavorite('o1'), isFalse);
      expect(notifier.state.actionError, contains(ApiError.sinConexion));
      notifier.clearActionError();
      expect(notifier.state.actionError, isNull);
    });
  });

  group('FavoritesScreen (#76)', () {
    Widget screen(_Repo repo) => ProviderScope(
          overrides: [marketplaceRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: FavoritesScreen()),
        );

    testWidgets('un error de carga muestra el motivo y Reintentar',
        (tester) async {
      repo.failWith = ApiError.sinConexion;
      await tester.pumpWidget(screen(repo));
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar tus favoritos'), findsOneWidget);
      expect(find.text(ApiError.sinConexion), findsOneWidget);
      // Antes decía esto aunque fuera un error:
      expect(find.text('Aún no guardas favoritos'), findsNothing);

      repo.failWith = null;
      repo.server = [_condor];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Cóndor Andino'), findsOneWidget);
    });

    testWidgets('sin favoritos invita a explorar el catálogo', (tester) async {
      await tester.pumpWidget(screen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Aún no guardas favoritos'), findsOneWidget);
      expect(find.text('Explorar el catálogo'), findsOneWidget);
    });
  });
}
