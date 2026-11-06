// TEMPORAL / herramienta de diseño: capturas del módulo de Subastas.
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/auctions/data/auction_ws_client.dart';
import 'package:narino_cultura/features/auctions/data/auctions_repository.dart';
import 'package:narino_cultura/features/auctions/domain/auction_bid_model.dart';
import 'package:narino_cultura/features/auctions/domain/auction_model.dart';
import 'package:narino_cultura/features/auctions/presentation/providers/auctions_provider.dart';
import 'package:narino_cultura/features/auctions/presentation/screens/auction_detail_screen.dart';
import 'package:narino_cultura/features/auctions/presentation/screens/auctions_screen.dart';
import 'package:narino_cultura/features/auctions/presentation/screens/create_auction_screen.dart';

import '../support/test_helpers.dart';
import 'preview_support.dart';

final _now = DateTime.now();

AuctionModel _a(String id, String titulo, {
  required Duration inicio,
  required Duration cierre,
  double base = 400000,
  double actual = 400000,
  String estado = 'activa',
  String? lider,
  String? ganador,
  List<AuctionBidModel> pujas = const [],
}) =>
    AuctionModel(
      id: id,
      obraId: 'o$id',
      obraTitulo: titulo,
      artistaNombre: 'María Torres',
      imagenUrl: null,
      precioBase: base,
      precioActual: actual,
      totalPujas: pujas.length,
      fechaInicio: _now.add(inicio),
      fechaCierre: _now.add(cierre),
      estado: estado,
      ganadorNombre: null,
      ultimasPujas: pujas,
      artistaId: 'artista-1',
      ganadorId: ganador,
      pujadorLiderId: lider,
      orderId: ganador == 'u1' ? 'orden-1' : null,
    );

final _lista = [
  _a('1', 'Carnaval de Negros y Blancos', inicio: const Duration(days: -1),
      cierre: const Duration(minutes: 42, seconds: 18), actual: 620000, lider: 'u1'),
  _a('2', 'Volcán Galeras al amanecer', inicio: const Duration(hours: -5),
      cierre: const Duration(days: 2, hours: 4), actual: 180000, base: 150000),
  _a('3', 'Barniz de Pasto: cóndor', inicio: const Duration(days: 1, hours: 3),
      cierre: const Duration(days: 8)),
];

class _Repo extends AuctionsRepository {
  @override
  Future<List<AuctionModel>> getAuctions({String? estado}) async => _lista;
  @override
  Future<AuctionModel> getDetail(String id) async => _a('1', 'Carnaval de Negros y Blancos',
      inicio: const Duration(days: -1), cierre: const Duration(minutes: 42),
      actual: 620000, base: 400000, lider: 'u1', pujas: const [
        AuctionBidModel(bidderName: 'Valeria', amount: 620000),
        AuctionBidModel(bidderName: 'Andrés', amount: 580000),
        AuctionBidModel(bidderName: 'Camila', amount: 510000),
      ]);
}

class _NoWs extends AuctionWsClient {
  @override
  Future<void> connect(String auctionId) async {}
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    final ov = [
      auctionsRepositoryProvider.overrideWithValue(_Repo()),
      currentUserIdProvider.overrideWith((ref) async => 'u1'),
      currentUserRoleProvider.overrideWith((ref) async => 'artista'),
      myArtworksForAuctionProvider.overrideWith((ref) async => <ArtworkModel>[
            testArtwork(id: 'x', titulo: 'Cóndor Andino', precio: 320000),
            testArtwork(id: 'y', titulo: 'Tejido Guaneña', precio: 95000),
          ]),
    ];
    testWidgets('subastas', skip: previewSkip, (t) async {
      await capture(t, name: 'subastas', dark: dark, overrides: ov, height: 1500,
          home: const MainShell(location: '/auctions', child: AuctionsScreen()));
    });
    testWidgets('subasta_detalle', skip: previewSkip, (t) async {
      await capture(t, name: 'subasta_detalle', dark: dark, overrides: ov, height: 1400,
          home: AuctionDetailScreen(auctionId: '1', ws: _NoWs()));
    });
    testWidgets('subasta_crear', skip: previewSkip, (t) async {
      await capture(t, name: 'subasta_crear', dark: dark, overrides: ov, height: 1300,
          home: const CreateAuctionScreen(), interact: (t) async {
        await t.tap(find.text('Cóndor Andino'));
      });
    });
  }
}
