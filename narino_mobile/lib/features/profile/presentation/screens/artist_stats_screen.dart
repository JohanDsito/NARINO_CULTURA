import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../../../artworks/presentation/providers/artwork_provider.dart';
import '../../../marketplace/domain/order_model.dart';
import '../../../marketplace/presentation/providers/cart_provider.dart';
import '../../../marketplace/presentation/widgets/tienda_ui.dart';
import '../providers/profile_provider.dart';

/// Ventas pagadas del artista; `null` si no se pudieron cargar (la pantalla
/// sigue mostrando las obras).
final _ventasProvider =
    FutureProvider.autoDispose<List<OrderModel>?>((ref) async {
  try {
    final list = await ref.read(marketplaceRepositoryProvider).getSalesHistory();
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
              child: _Contenido(
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

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.obras,
    required this.seguidores,
    required this.ventas,
  });

  final List<ArtworkModel> obras;
  final int seguidores;
  final AsyncValue<List<OrderModel>?> ventas;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final vistas = obras.fold<int>(0, (s, a) => s + a.viewsCount);
    final vendidas = obras.where((a) => a.estado == 'vendida').length;
    final enSubasta = obras.where((a) => a.estado == 'en_subasta').length;
    final top = [...obras]..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final conVistas = top.where((a) => a.viewsCount > 0).take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _Cifra(
                icon: Icons.visibility_outlined,
                accent: nc.azulA,
                valor: _miles(vistas),
                label: 'vistas de tus obras',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Cifra(
                icon: Icons.favorite_border_rounded,
                accent: nc.catalogo,
                valor: _miles(seguidores),
                label: seguidores == 1 ? 'persona te sigue' : 'personas te siguen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Cifra(
                icon: Icons.palette_outlined,
                accent: nc.naranjaA,
                valor: '${obras.length}',
                label: obras.length == 1 ? 'obra publicada' : 'obras publicadas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Cifra(
                icon: Icons.sell_outlined,
                accent: nc.oroA,
                valor: '$vendidas',
                label: enSubasta > 0
                    ? '${vendidas == 1 ? 'vendida' : 'vendidas'} · $enSubasta en subasta'
                    : (vendidas == 1 ? 'obra vendida' : 'obras vendidas'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Ingresos(ventas: ventas),
        const SizedBox(height: 24),
        const NcSectionHeader(
          title: 'Lo más visto',
          padding: EdgeInsets.symmetric(horizontal: 4),
        ),
        const SizedBox(height: 12),
        if (conVistas.isEmpty)
          NcEmptyState(
            icon: Icons.auto_graph_rounded,
            accent: nc.azulA,
            title: obras.isEmpty ? 'Aún no tienes obras' : 'Aún sin vistas',
            message: obras.isEmpty
                ? 'Publica tu primera obra y aquí verás cómo le va.'
                : 'Comparte tus obras en tus redes para que más gente las vea.',
            actionLabel: obras.isEmpty ? 'Publicar una obra' : null,
            onAction: obras.isEmpty
                ? () => context.push('/artworks/publish')
                : null,
            padding: EdgeInsets.zero,
          )
        else
          for (final (i, a) in conVistas.indexed) ...[
            _FilaTop(
              puesto: i + 1,
              obra: a,
              fraccion: a.viewsCount / conVistas.first.viewsCount,
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

String _miles(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.icon,
    required this.accent,
    required this.valor,
    required this.label,
  });

  final IconData icon;
  final NcAccent accent;
  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      label: '$valor $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: nc.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: nc.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NcAccentIcon(icon: icon, accent: accent, size: 34),
            const SizedBox(height: 12),
            Text(valor,
                style: AppTypography.displayBold(color: nc.textPrimary)
                    .copyWith(fontSize: 26)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 2,
                style: AppTypography.bodySmall(color: nc.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Ingresos extends StatelessWidget {
  const _Ingresos({required this.ventas});

  final AsyncValue<List<OrderModel>?> ventas;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final lista = ventas.valueOrNull;
    final now = DateTime.now();
    final mes = (lista ?? const <OrderModel>[])
        .where((o) => o.creadoEn.year == now.year && o.creadoEn.month == now.month)
        .fold<double>(0, (s, o) => s + o.montoVenta);
    final total =
        (lista ?? const <OrderModel>[]).fold<double>(0, (s, o) => s + o.montoVenta);

    return NcCard(
      padding: const EdgeInsets.all(18),
      onTap: () => context.push('/marketplace/sales'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NcAccentIcon(
                  icon: Icons.payments_outlined, accent: nc.tienda, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Ingresos de ${_mesNombre(now.month)}',
                    style: AppTypography.labelSemiBold(
                        color: nc.textSecondary)),
              ),
              Icon(Icons.chevron_right_rounded, color: nc.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          if (ventas.isLoading)
            const LinearProgressIndicator()
          else if (lista == null)
            Text('No pudimos cargar tus ventas. Toca para verlas.',
                style: AppTypography.bodySmall(color: nc.textSecondary))
          else ...[
            Text(formatCOP(mes),
                style: AppTypography.displayBold(color: nc.tienda.ink)
                    .copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              lista.isEmpty
                  ? 'Todavía no tienes ventas pagadas.'
                  : '${formatCOP(total)} en total · '
                      '${lista.length} ${lista.length == 1 ? 'venta' : 'ventas'}',
              style: AppTypography.bodySmall(color: nc.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  static String _mesNombre(int m) => kMesesNombre[m - 1].toLowerCase();
}

class _FilaTop extends StatelessWidget {
  const _FilaTop({
    required this.puesto,
    required this.obra,
    required this.fraccion,
  });

  final int puesto;
  final ArtworkModel obra;
  final double fraccion;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final medalla = switch (puesto) {
      1 => nc.oroA,
      2 => nc.naranjaA,
      3 => nc.catalogo,
      _ => nc.azulA,
    };
    return Semantics(
      button: true,
      label: 'Puesto $puesto: ${obra.titulo}, ${obra.viewsCount} vistas',
      excludeSemantics: true,
      child: NcPressable(
        onTap: () => context.push('/artworks/${obra.id}'),
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: nc.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: nc.border),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ObraThumb(
                      url: obra.imagenes.isNotEmpty ? obra.imagenes.first : null,
                      size: 56),
                  Positioned(
                    left: -4,
                    top: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: medalla.fill,
                        shape: BoxShape.circle,
                        border: Border.all(color: nc.bgCard, width: 2),
                      ),
                      child: Text('$puesto',
                          style: AppTypography.labelMedium(
                                  color: medalla.onFill)
                              .copyWith(
                                  fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(obra.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.labelSemiBold(color: nc.textPrimary)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: fraccion.clamp(0.04, 1.0),
                        minHeight: 6,
                        backgroundColor: nc.itemFill,
                        color: medalla.fill,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                        '${_miles(obra.viewsCount)} '
                        '${obra.viewsCount == 1 ? 'vista' : 'vistas'}',
                        style: AppTypography.bodySmall(
                            color: nc.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: nc.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
