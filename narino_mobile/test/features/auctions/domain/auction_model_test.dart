import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/auctions/domain/auction_bid_model.dart';
import 'package:narino_cultura/features/auctions/domain/auction_model.dart';

void main() {
  group('AuctionBidModel.fromJson', () {
    test('mapea los campos en español (monto/creado_en)', () {
      final bid = AuctionBidModel.fromJson({
        'pujador_nombre': 'Carlos',
        'monto': 15000,
        'creado_en': '2025-05-01T10:00:00.000Z',
      });

      expect(bid.bidderName, 'Carlos');
      expect(bid.amount, 15000.0);
      expect(bid.createdAt, DateTime.parse('2025-05-01T10:00:00.000Z'));
    });

    test('mapea los campos en inglés (amount/created_at/bidder_name)', () {
      final bid = AuctionBidModel.fromJson({
        'bidder_name': 'Ana',
        'amount': 2500.5,
        'created_at': '2025-06-01T08:30:00.000Z',
      });

      expect(bid.bidderName, 'Ana');
      expect(bid.amount, 2500.5);
      expect(bid.createdAt, DateTime.parse('2025-06-01T08:30:00.000Z'));
    });

    test('usa "usuario" y "fecha" como último recurso', () {
      final bid = AuctionBidModel.fromJson({
        'usuario': 'invitado1',
        'fecha': '2025-07-01T00:00:00.000Z',
      });

      expect(bid.bidderName, 'invitado1');
      expect(bid.createdAt, DateTime.parse('2025-07-01T00:00:00.000Z'));
    });

    test('parsea el monto desde un string numérico', () {
      final bid = AuctionBidModel.fromJson({
        'monto': '3000',
      });

      expect(bid.amount, 3000.0);
    });

    test('usa 0.0 cuando el monto falta o no es parseable', () {
      final bidFaltante = AuctionBidModel.fromJson({});
      final bidInvalido = AuctionBidModel.fromJson({'monto': 'no-numero'});

      expect(bidFaltante.amount, 0.0);
      expect(bidInvalido.amount, 0.0);
    });

    test('usa "Pujador" por defecto cuando no hay nombre', () {
      final bid = AuctionBidModel.fromJson({'monto': 100});

      expect(bid.bidderName, 'Pujador');
    });

    test('createdAt es null cuando la fecha falta o es inválida', () {
      final sinFecha = AuctionBidModel.fromJson({});
      final fechaInvalida = AuctionBidModel.fromJson({'fecha': 'no-es-fecha'});

      expect(sinFecha.createdAt, isNull);
      expect(fechaInvalida.createdAt, isNull);
    });
  });

  group('AuctionModel.fromJson', () {
    Map<String, dynamic> baseJson() => {
          'id': 'auction-1',
          'artwork_id': 'obra-1',
          'obra_titulo': 'Barniz de Pasto',
          'artista_nombre': 'Ana Díaz',
          'artista_id': 'artist-1',
          'imagen_url': 'https://cdn.test/obra.jpg',
          'base_price': 100000,
          'current_price': 120000,
          'total_pujas': 3,
          'starts_at': '2025-03-01T12:00:00.000Z',
          'ends_at': '2025-03-10T12:00:00.000Z',
          'status': 'ACTIVA',
          'winner': 'user-9',
          'ganador_nombre': 'Pedro',
          'order_id': 'order-1',
          'bids': [
            {'monto': 110000, 'pujador_nombre': 'Pedro'},
            {'monto': 120000, 'pujador_nombre': 'Pedro'},
          ],
        };

    test('mapea los campos en inglés del backend a los del modelo', () {
      final auction = AuctionModel.fromJson(baseJson());

      expect(auction.id, 'auction-1');
      expect(auction.obraId, 'obra-1');
      expect(auction.obraTitulo, 'Barniz de Pasto');
      expect(auction.artistaNombre, 'Ana Díaz');
      expect(auction.artistaId, 'artist-1');
      expect(auction.imagenUrl, 'https://cdn.test/obra.jpg');
      expect(auction.precioBase, 100000.0);
      expect(auction.precioActual, 120000.0);
      expect(auction.totalPujas, 3);
      expect(auction.fechaInicio, DateTime.parse('2025-03-01T12:00:00.000Z'));
      expect(auction.fechaCierre, DateTime.parse('2025-03-10T12:00:00.000Z'));
      expect(auction.estado, 'activa');
      expect(auction.ganadorId, 'user-9');
      expect(auction.ganadorNombre, 'Pedro');
      expect(auction.orderId, 'order-1');
      expect(auction.ultimasPujas, hasLength(2));
    });

    test('normaliza el estado a minúsculas', () {
      expect(
        AuctionModel.fromJson({...baseJson(), 'status': 'CERRADA'}).estado,
        'cerrada',
      );
      final sinStatus = {...baseJson()}
        ..remove('status')
        ..['estado'] = 'Cancelada';
      expect(AuctionModel.fromJson(sinStatus).estado, 'cancelada');
    });

    test('usa "activa" como estado por defecto cuando no viene status/estado',
        () {
      final json = {...baseJson()}
        ..remove('status')
        ..remove('estado');

      expect(AuctionModel.fromJson(json).estado, 'activa');
    });

    test('lee campos anidados desde el mapa "obra" cuando faltan los planos',
        () {
      final json = {
        'id': 'auction-2',
        'obra': {
          'id': 'obra-2',
          'titulo': 'Máscara de Sibundoy',
          'imagen_principal': 'https://cdn.test/mascara.jpg',
        },
        'base_price': 5000,
      };

      final auction = AuctionModel.fromJson(json);

      expect(auction.obraId, 'obra-2');
      expect(auction.obraTitulo, 'Máscara de Sibundoy');
      expect(auction.imagenUrl, 'https://cdn.test/mascara.jpg');
    });

    test('precioActual usa precioBase cuando no viene current_price', () {
      final json = {...baseJson()}..remove('current_price');

      final auction = AuctionModel.fromJson(json);

      expect(auction.precioActual, auction.precioBase);
    });

    test('precioBase es 0.0 cuando no es numérico ni parseable', () {
      final json = {...baseJson()}
        ..remove('base_price')
        ..remove('current_price');

      final auction = AuctionModel.fromJson(json);

      expect(auction.precioBase, 0.0);
      expect(auction.precioActual, 0.0);
    });

    test('parsea precios enviados como strings', () {
      final json = {
        ...baseJson(),
        'base_price': '75000',
        'current_price': '80000',
      };

      final auction = AuctionModel.fromJson(json);

      expect(auction.precioBase, 75000.0);
      expect(auction.precioActual, 80000.0);
    });

    test('totalPujas cae al tamaño de la lista de pujas si no viene el campo',
        () {
      final json = {...baseJson()}..remove('total_pujas');

      final auction = AuctionModel.fromJson(json);

      expect(auction.totalPujas, 2);
    });

    test('ultimasPujas es vacía cuando no hay bids/pujas/ultimas_pujas', () {
      final json = {...baseJson()}..remove('bids');

      final auction = AuctionModel.fromJson(json);

      expect(auction.ultimasPujas, isEmpty);
      expect(auction.totalPujas, 3); // sigue viniendo de total_pujas
    });

    test('imagenUrl es null cuando viene vacío o solo espacios', () {
      final json = {...baseJson(), 'imagen_url': '   '};

      final auction = AuctionModel.fromJson(json);

      expect(auction.imagenUrl, isNull);
    });

    test('usa valores por defecto "Obra"/"Artista" cuando faltan título y artista',
        () {
      final json = {'id': 'auction-3', 'base_price': 1000};

      final auction = AuctionModel.fromJson(json);

      expect(auction.obraTitulo, 'Obra');
      expect(auction.artistaNombre, 'Artista');
    });

    test('id cae a obraId cuando no viene "id" explícito', () {
      final json = {'obraId': 'fallback-id', 'base_price': 1000};

      final auction = AuctionModel.fromJson(json);

      expect(auction.id, 'fallback-id');
    });

    test('id es cadena vacía cuando no viene ni id ni obraId', () {
      final auction = AuctionModel.fromJson({'base_price': 1000});

      expect(auction.id, '');
      expect(auction.obraId, '');
    });

    test('fechaInicio/fechaCierre caen a "ahora" cuando faltan o son inválidas',
        () {
      final before = DateTime.now();
      final json = {
        ...baseJson(),
        'starts_at': 'no-es-fecha',
        'ends_at': null,
      };

      final auction = AuctionModel.fromJson(json);
      final after = DateTime.now();

      expect(
        auction.fechaInicio.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        auction.fechaInicio.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        auction.fechaCierre.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('AuctionModel.copyWith', () {
    AuctionModel baseModel() => AuctionModel(
          id: '1',
          obraId: 'obra-1',
          obraTitulo: 'Obra',
          artistaNombre: 'Artista',
          imagenUrl: null,
          precioBase: 1000,
          precioActual: 1000,
          totalPujas: 0,
          fechaInicio: DateTime(2025, 1, 1),
          fechaCierre: DateTime(2025, 1, 10),
          estado: 'activa',
          ganadorNombre: null,
          ultimasPujas: const [],
        );

    test('actualiza solo los campos provistos y preserva el resto', () {
      final updated = baseModel().copyWith(
        precioActual: 1500,
        totalPujas: 4,
        estado: 'cerrada',
        ganadorNombre: 'Pedro',
        ganadorId: 'user-1',
        orderId: 'order-9',
      );

      expect(updated.precioActual, 1500);
      expect(updated.totalPujas, 4);
      expect(updated.estado, 'cerrada');
      expect(updated.ganadorNombre, 'Pedro');
      expect(updated.ganadorId, 'user-1');
      expect(updated.orderId, 'order-9');
      // Campos no tocados se preservan
      expect(updated.id, '1');
      expect(updated.obraId, 'obra-1');
      expect(updated.precioBase, 1000);
      expect(updated.fechaInicio, DateTime(2025, 1, 1));
    });

    test('sin argumentos conserva todos los valores originales', () {
      final original = baseModel();
      final copy = original.copyWith();

      expect(copy.precioActual, original.precioActual);
      expect(copy.totalPujas, original.totalPujas);
      expect(copy.estado, original.estado);
      expect(copy.ganadorNombre, original.ganadorNombre);
      expect(copy.fechaCierre, original.fechaCierre);
    });
  });
}
