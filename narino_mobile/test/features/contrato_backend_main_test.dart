// Campos nuevos del backend de main (PRs #172–#177) que lee la app.
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/auctions/domain/auction_bid_model.dart';
import 'package:narino_cultura/features/auctions/domain/auction_model.dart';
import 'package:narino_cultura/features/events/domain/event_model.dart';
import 'package:narino_cultura/features/marketplace/domain/cart_item_model.dart';
import 'package:narino_cultura/features/marketplace/domain/favorite_model.dart';

void main() {
  test('AuctionModel lee artwork_title, artwork_image_url, artist_name y bids_count', () {
    final a = AuctionModel.fromJson(const {
      'id': 'a1',
      'artwork': 'o1',
      'artwork_title': 'Cóndor Andino',
      'artwork_image_url': 'https://cdn/x.jpg',
      'artist_name': 'María Torres',
      'bids_count': 7,
      'base_price': '100000',
      'current_price': '150000',
      'status': 'ACTIVA',
      'starts_at': '2026-11-01T10:00:00Z',
      'ends_at': '2026-11-10T10:00:00Z',
    });
    expect(a.obraTitulo, 'Cóndor Andino');
    expect(a.imagenUrl, 'https://cdn/x.jpg');
    expect(a.artistaNombre, 'María Torres');
    expect(a.totalPujas, 7);
  });

  test('AuctionBidModel lee is_mine del historial de pujas', () {
    final b = AuctionBidModel.fromJson(const {
      'id': 'b1',
      'amount': '150000.00',
      'bidder_name': 'Ana P.',
      'is_mine': true,
      'created_at': '2026-11-06T10:00:00Z',
    });
    expect(b.esMia, isTrue);
    expect(b.bidderName, 'Ana P.');
    expect(b.amount, 150000);
  });

  test('EventModel usa is_registered', () {
    final e = EventModel.fromJson(const {
      'id': 'e1',
      'title': 'Taller',
      'event_type': 'TALLER',
      'start_date': '2026-12-01T10:00:00Z',
      'end_date': '2026-12-01T12:00:00Z',
      'is_registered': true,
    });
    expect(e.estaSuscrito, isTrue);
  });

  test('Carrito y favoritos leen imagen, artista, precio y estado de la obra', () {
    final c = CartItemModel.fromJson(const {
      'id': 'c1',
      'artwork': 'o1',
      'artwork_title': 'Tejido',
      'artwork_price': '95000.00',
      'artwork_status': 'DISPONIBLE',
      'artwork_image_url': 'https://cdn/t.jpg',
      'artist_name': 'Luis Zambrano',
    });
    expect(c.imagenUrl, 'https://cdn/t.jpg');
    expect(c.artistaNombre, 'Luis Zambrano');
    expect(c.precio, 95000);

    final f = FavoriteModel.fromJson(const {
      'id': 'f1',
      'artwork_id': 'o1',
      'artwork_title': 'Tejido',
      'artwork_price': '95000.00',
      'artwork_status': 'VENDIDA',
      'artwork_image_url': 'https://cdn/t.jpg',
      'artist_name': 'Luis Zambrano',
    });
    expect(f.imagenUrl, 'https://cdn/t.jpg');
    expect(f.artistaNombre, 'Luis Zambrano');
    expect(f.precio, 95000);
    expect(f.isVendida, isTrue);
  });
}
