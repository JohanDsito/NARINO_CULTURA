import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/api_error.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';

import '../../../../support/test_helpers.dart';

/// Backend falso con [total] obras en páginas de 20.
class _Repo extends ArtworkRepository {
  _Repo(this.total);

  final int total;
  final pedidas = <int>[];
  Object? failOn; // número de página que falla
  final gates = <String, Completer<void>>{}; // búsqueda → respuesta retenida

  @override
  Future<({List<ArtworkModel> artworks, int total})> getCatalog({
    String? search,
    String? categoria,
    String? tecnica,
    double? precioMin,
    double? precioMax,
    String ordenarPor = 'fecha',
    int page = 1,
  }) async {
    pedidas.add(page);
    await gates[search ?? '']?.future;
    if (failOn == page) throw ApiError.sinConexion;
    final desde = (page - 1) * 20;
    final hasta = (desde + 20).clamp(0, total);
    final obras = [
      for (var i = desde; i < hasta; i++)
        testArtwork(id: '${search ?? ''}$i', titulo: 'Obra $i'),
    ];
    return (artworks: obras, total: total);
  }
}

void main() {
  test('carga la primera página y sabe que quedan más (MO-LOAD-01)', () async {
    final n = ArtworkNotifier(_Repo(130));
    await n.loadCatalog();

    expect(n.state.artworks, hasLength(20));
    expect(n.state.totalResultados, 130);
    expect(n.state.hasMore, isTrue);
  });

  test('loadMore agrega páginas hasta traer las 130 obras', () async {
    final repo = _Repo(130);
    final n = ArtworkNotifier(repo);
    await n.loadCatalog();
    while (n.state.hasMore) {
      await n.loadMore();
    }

    expect(n.state.artworks, hasLength(130));
    expect(n.state.artworks.map((a) => a.id).toSet(), hasLength(130));
    expect(repo.pedidas, [1, 2, 3, 4, 5, 6, 7]);

    // Al final ya no pide más.
    await n.loadMore();
    expect(repo.pedidas, hasLength(7));
  });

  test('no pide la misma página dos veces si el scroll insiste', () async {
    final repo = _Repo(60);
    final n = ArtworkNotifier(repo);
    await n.loadCatalog();

    await Future.wait([n.loadMore(), n.loadMore(), n.loadMore()]);

    expect(repo.pedidas, [1, 2]);
    expect(n.state.artworks, hasLength(40));
  });

  test('si falla una página conserva lo cargado y deja reintentar', () async {
    final repo = _Repo(60)..failOn = 2;
    final n = ArtworkNotifier(repo);
    await n.loadCatalog();
    await n.loadMore();

    expect(n.state.artworks, hasLength(20));
    expect(n.state.loadMoreError, ApiError.sinConexion);

    repo.failOn = null;
    await n.loadMore();
    expect(n.state.artworks, hasLength(40));
    expect(n.state.loadMoreError, isNull);
  });

  test('una búsqueda vieja que responde tarde no pisa la nueva', () async {
    final repo = _Repo(60);
    final n = ArtworkNotifier(repo);
    repo.gates['ca'] = Completer();

    final vieja = n.loadCatalog()..ignore();
    n.setBusqueda('ca'); // respuesta retenida
    n.setBusqueda('cab'); // responde primero
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    repo.gates['ca']!.complete();
    await vieja;
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(n.state.busqueda, 'cab');
    expect(n.state.artworks.first.id, startsWith('cab'));
  });
}
