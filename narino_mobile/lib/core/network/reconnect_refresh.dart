import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/artworks/presentation/providers/artwork_provider.dart';
import '../../features/auctions/presentation/providers/auctions_provider.dart';
import '../../features/events/presentation/providers/events_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/home_screen/agenda_section.dart';
import '../../features/home/presentation/screens/home_screen/featured_strip.dart';
import '../../features/marketplace/presentation/providers/favorites_provider.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';

/// Al volver la red, recarga solo lo que quedó en error (MO-DISP-02).
///
/// Lo que cargó bien no se toca, y las pantallas que nunca se abrieron no se
/// piden (`ref.exists`), para no gastar datos apenas regresa la conexión.
/// Devuelve cuántas secciones se recargaron.
int refreshAfterReconnect(WidgetRef ref) {
  var recargadas = 0;

  if (ref.exists(artworkProvider) && ref.read(artworkProvider).hasError) {
    ref.read(artworkProvider.notifier).loadCatalog();
    recargadas++;
  }
  if (ref.exists(favoritesProvider) && ref.read(favoritesProvider).hasError) {
    ref.read(favoritesProvider.notifier).loadFavorites();
    recargadas++;
  }
  if (ref.exists(eventsProvider) && ref.read(eventsProvider).hasError) {
    ref.read(eventsProvider.notifier).loadEvents();
    recargadas++;
  }
  if (ref.exists(auctionsProvider) && ref.read(auctionsProvider).hasError) {
    ref.read(auctionsProvider.notifier).loadActive();
    recargadas++;
  }

  // FutureProviders de Inicio y Tienda: invalidarlos vuelve a pedirlos.
  for (final provider in [
    homeFeaturedArtworksProvider(kHomeFeaturedLimit),
    homeUpcomingEventsProvider(kHomeAgendaLimit),
    tiendaObrasProvider,
  ]) {
    if (ref.exists(provider) && ref.read(provider).hasError) {
      ref.invalidate(provider);
      recargadas++;
    }
  }
  return recargadas;
}
