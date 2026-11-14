import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../marketplace/domain/order_model.dart';
import '../../../marketplace/presentation/providers/cart_provider.dart';
import '../providers/profile_provider.dart';
import 'artist_stats_screen/artist_stats_content.dart';

/// Ventas pagadas del artista; `null` si no se pudieron cargar (la pantalla
/// sigue mostrando las obras).
final _ventasProvider =
    FutureProvider.autoDispose<List<OrderModel>?>((ref) async {
  try {
    final list =
        await ref.read(marketplaceRepositoryProvider).getSalesHistory();
    return list.where((o) => o.isCompletado).toList();
  } catch (_) {
    return null;
  }
});

/// Estadísticas del artista con datos reales: obras, vistas, seguidores y
/// ventas. (El backend no da visitas por mes ni seguidores nuevos, así que
/// no se muestran.)
class ArtistStatsScreen extends ConsumerWidget {
  const ArtistStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final profile = ref.watch(myProfileProvider).profile;
    final slug = profile?.id ?? '';

    Widget body;
    if (role != null && role != 'artista') {
      body = ListView(children: [
        NcEmptyState(
          icon: Icons.insights_rounded,
          accent: nc.catalogo,
          title: 'Las estadísticas son para artistas',
          message: 'Cuando publiques obras como artista, aquí verás cuántas '
              'personas las miran y cuánto has vendido.',
        ),
      ]);
    } else if (slug.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ref.watch(artistArtworksProvider(slug)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ListView(children: [
              NcEmptyState(
                icon: Icons.wifi_off_rounded,
                accent: nc.tomateA,
                title: 'No pudimos cargar tus estadísticas',
                message: 'Revisa tu conexión e intenta de nuevo.',
                actionLabel: 'Reintentar',
                onAction: () => ref.invalidate(artistArtworksProvider(slug)),
              ),
            ]),
            data: (obras) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_ventasProvider);
                return ref.refresh(artistArtworksProvider(slug).future);
              },
              child: ArtistStatsContent(
                obras: obras,
                seguidores: profile?.seguidores ?? 0,
                ventas: ref.watch(_ventasProvider),
              ),
            ),
          );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis estadísticas')),
      body: body,
    );
  }
}
