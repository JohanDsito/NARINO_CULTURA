// TEMPORAL / herramienta de diseño: capturas del módulo Tienda.
import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/app.dart';
import 'package:narino_cultura/core/providers/user_role_provider.dart';
import 'package:narino_cultura/features/artworks/data/artwork_repository.dart';
import 'package:narino_cultura/features/artworks/domain/artwork_model.dart';
import 'package:narino_cultura/features/artworks/presentation/providers/artwork_provider.dart';
import 'package:narino_cultura/features/marketplace/data/marketplace_repository.dart';
import 'package:narino_cultura/features/marketplace/domain/cart_item_model.dart';
import 'package:narino_cultura/features/marketplace/domain/favorite_model.dart';
import 'package:narino_cultura/features/marketplace/domain/order_model.dart';
import 'package:narino_cultura/features/marketplace/presentation/providers/cart_provider.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/cart_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/checkout_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/payment_result_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/purchase_history_screen.dart';
import 'package:narino_cultura/features/marketplace/presentation/screens/sales_history_screen.dart';

import '../support/test_helpers.dart';
import 'preview_support.dart';

final _items = [
  const OrderItemModel(
      obraId: '1', obraTitulo: 'Cóndor Andino', artistaNombre: 'María Torres', precio: 320000),
  const OrderItemModel(
      obraId: '2', obraTitulo: 'Tejido Guaneña', artistaNombre: 'Carlos Díaz', precio: 95000),
];
final _orders = [
  OrderModel(id: 'a1b2c3d4-0000-0000-0000-000000000001', estado: 'completado', total: 415000, creadoEn: DateTime(2026, 11, 2), items: _items, comprobantePdfUrl: 'https://x/c.pdf'),
  OrderModel(id: 'f9e8d7c6-0000-0000-0000-000000000002', estado: 'pendiente', total: 180000, creadoEn: DateTime(2026, 11, 5), items: [_items.first]),
  OrderModel(id: '0b1c2d3e-0000-0000-0000-000000000003', estado: 'fallido', total: 95000, creadoEn: DateTime(2026, 10, 20), items: [_items.last]),
];

class _MRepo extends MarketplaceRepository {
  @override
  Future<List<CartItemModel>> getCart() async => const [
        CartItemModel(id: 'c1', obraId: '1', obraTitulo: 'Cóndor Andino', artistaNombre: 'María Torres', precio: 320000),
        CartItemModel(id: 'c2', obraId: '2', obraTitulo: 'Volcán Galeras al amanecer', artistaNombre: 'Luis Zambrano', precio: 180000),
        CartItemModel(id: 'c3', obraId: '3', obraTitulo: 'Carnaval Eterno', artistaNombre: 'Ana Benavides', precio: 540000, estadoObra: 'VENDIDA'),
      ];
  @override
  Future<List<FavoriteModel>> getFavorites() async => const [
        FavoriteModel(id: 'f1', obraId: '1', obraTitulo: 'Cóndor Andino', artistaNombre: 'María Torres', estado: 'disponible', precio: 320000),
        FavoriteModel(id: 'f2', obraId: '2', obraTitulo: 'Volcán Galeras', artistaNombre: 'Luis Zambrano', estado: 'en_subasta', precio: 180000),
      ];
  @override
  Future<List<OrderModel>> getPurchaseHistory() async => _orders;
  @override
  Future<List<OrderModel>> getSalesHistory() async => [_orders.first];
  @override
  Future<OrderModel> getOrderDetail(String id) async => _orders.first;
}

class _ARepo extends ArtworkRepository {
  @override
  Future<List<ArtworkModel>> getDisponibles() async => [
        testArtwork(id: '1', titulo: 'Cóndor Andino', artistaNombre: 'María Torres', precio: 320000),
        testArtwork(id: '2', titulo: 'Tejido Guaneña', artistaNombre: 'Carlos Díaz', precio: 95000),
      ];
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final dark in [true, false]) {
    final ov = [
      marketplaceRepositoryProvider.overrideWithValue(_MRepo()),
      artworkRepositoryProvider.overrideWithValue(_ARepo()),
      currentUserRoleProvider.overrideWith((ref) async => 'artista'),
    ];
    testWidgets('tienda', skip: previewSkip, (t) async {
      await capture(t, name: 'tienda', dark: dark, overrides: ov,
          home: const MainShell(location: '/marketplace', child: MarketplaceScreen()));
    });
    testWidgets('carrito', skip: previewSkip, (t) async {
      await capture(t, name: 'carrito', dark: dark, overrides: ov, home: const CartScreen());
    });
    testWidgets('pagar', skip: previewSkip, (t) async {
      await capture(t, name: 'pagar', dark: dark, overrides: ov,
          home: const CheckoutScreen(orderId: 'a1b2c3d4-0000'));
    });
    testWidgets('compras', skip: previewSkip, (t) async {
      await capture(t, name: 'compras', dark: dark, overrides: ov, home: const PurchaseHistoryScreen());
    });
    testWidgets('ventas', skip: previewSkip, (t) async {
      await capture(t, name: 'ventas', dark: dark, overrides: ov, home: const SalesHistoryScreen());
    });
    testWidgets('favoritos', skip: previewSkip, (t) async {
      await capture(t, name: 'favoritos', dark: dark, overrides: ov, home: const FavoritesScreen());
    });
    testWidgets('pago_ok', skip: previewSkip, (t) async {
      await capture(t, name: 'pago_ok', dark: dark, overrides: ov,
          home: const PaymentResultScreen(orderId: 'a1b2c3d4-0000', success: true));
    });
  }
}
