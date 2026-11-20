import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../artworks/domain/artwork_model.dart';
import '../../../../marketplace/domain/order_model.dart';
import 'formato_miles.dart';
import 'income_card.dart';
import 'stat_figure_card.dart';
import 'top_artwork_row.dart';

class ArtistStatsContent extends StatelessWidget {
  const ArtistStatsContent({
    super.key,
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
    final top = [...obras]
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final conVistas = top.where((a) => a.viewsCount > 0).take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: StatFigureCard(
                icon: Icons.visibility_outlined,
                accent: nc.azulA,
                valor: formatMiles(vistas),
                label: 'vistas de tus obras',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatFigureCard(
                icon: Icons.favorite_border_rounded,
                accent: nc.catalogo,
                valor: formatMiles(seguidores),
                label:
                    seguidores == 1 ? 'persona te sigue' : 'personas te siguen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatFigureCard(
                icon: Icons.palette_outlined,
                accent: nc.naranjaA,
                valor: '${obras.length}',
                label:
                    obras.length == 1 ? 'obra publicada' : 'obras publicadas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatFigureCard(
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
        IncomeCard(ventas: ventas),
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
            onAction:
                obras.isEmpty ? () => context.push('/artworks/publish') : null,
            padding: EdgeInsets.zero,
          )
        else
          for (final (i, a) in conVistas.indexed) ...[
            TopArtworkRow(
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
