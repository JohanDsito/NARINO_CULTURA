import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../auctions/presentation/providers/auctions_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../marketplace/presentation/providers/cart_provider.dart';
import '../../../marketplace/presentation/providers/favorites_provider.dart';
import '../../../marketplace/presentation/providers/orders_provider.dart';
import '../../../musicians/presentation/providers/seguidos_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../profile/presentation/providers/active_sessions_provider.dart';
import '../../../profile/presentation/providers/change_email_provider.dart';
import '../../../profile/presentation/providers/delete_account_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'auth_provider.dart';

/// Providers que viven toda la app y guardan datos de quien inició sesión.
/// Si no se reinician, la siguiente persona que entre ve el carrito, los
/// favoritos o el perfil de la anterior.
final List<ProviderOrFamily> userScopedProviders = [
  authProvider,
  currentUserClaimsProvider,
  currentUserRoleProvider,
  currentUserIdProvider,
  isAdminProvider,
  profileProvider,
  myFollowingProvider,
  activeSessionsProvider,
  changeEmailProvider,
  deleteAccountProvider,
  cartProvider,
  favoritesProvider,
  ordersProvider,
  orderDetailProvider,
  seguidosProvider,
  notificationsProvider,
  unreadNotificationsCountProvider,
  artworkProvider, // marca qué obras son favoritas
  eventsProvider, // marca en cuáles está inscrita
  auctionsProvider,
];

/// Reinicia todo el estado del usuario. Se usa al cerrar sesión, al eliminar
/// la cuenta y cuando la sesión expira (MO-SEG-04).
void resetUserSession(void Function(ProviderOrFamily provider) invalidate) {
  for (final provider in userScopedProviders) {
    invalidate(provider);
  }
}
