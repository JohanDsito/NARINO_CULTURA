import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/network/api_error.dart';
import 'package:narino_cultura/core/network/reconnect_refresh.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';

import '../../support/test_helpers.dart';

/// Falla mientras [online] sea `false` (como sin red) y responde al volver.
class _Repo extends FakeArtworkRepository {
  bool online = false;
  int pedidas = 0;

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
    pedidas++;
    if (!online) throw ApiError.sinConexion;
    return (artworks: [testArtwork(id: '1')], total: 1);
  }
}

void main() {
  late _Repo repo;
  late WidgetRef widgetRef;

  Future<void> montar(WidgetTester tester) => tester.pumpWidget(ProviderScope(
        overrides: [artworkRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            widgetRef = ref;
            ref.watch(artworkProvider); // el catálogo está abierto
            return const SizedBox();
          }),
        ),
      ));

  setUp(() => repo = _Repo());

  // MO-DISP-02: al volver la red se recarga lo que falló, sin tocar Reintentar.
  testWidgets('recarga el catálogo que quedó en error', (tester) async {
    await montar(tester);
    await widgetRef.read(artworkProvider.notifier).loadCatalog();
    expect(widgetRef.read(artworkProvider).hasError, isTrue);

    repo.online = true;
    expect(refreshAfterReconnect(widgetRef), 1);
    await tester.pump();

    expect(widgetRef.read(artworkProvider).hasError, isFalse);
    expect(widgetRef.read(artworkProvider).artworks, hasLength(1));
  });

  testWidgets('no vuelve a pedir lo que cargó bien', (tester) async {
    repo.online = true;
    await montar(tester);
    await widgetRef.read(artworkProvider.notifier).loadCatalog();
    final antes = repo.pedidas;

    expect(refreshAfterReconnect(widgetRef), 0);
    expect(repo.pedidas, antes);
  });
}
