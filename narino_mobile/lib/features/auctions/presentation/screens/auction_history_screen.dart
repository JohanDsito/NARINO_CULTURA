import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';
import '../widgets/subasta_ui.dart';

const _estados = <(String?, String)>[
  (null, 'Todas'),
  ('activa', 'Activas'),
  ('pendiente', 'En revisión'),
  ('cerrada', 'Finalizadas'),
  ('cancelada', 'Canceladas'),
];

/// Historial: "Mis pujas" (voy ganando o gané) y "Mis subastas" (las que abrí).
class AuctionHistoryScreen extends ConsumerStatefulWidget {
  const AuctionHistoryScreen({super.key});

  @override
  ConsumerState<AuctionHistoryScreen> createState() =>
      _AuctionHistoryScreenState();
}

class _AuctionHistoryScreenState extends ConsumerState<AuctionHistoryScreen> {
  String? _estado;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi historial de subastas'),
          // Antes: etiqueta inactiva fija en blanco (invisible en claro).
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mis pujas'),
              Tab(text: 'Mis subastas'),
            ],
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                itemCount: _estados.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (valor, label) = _estados[i];
                  final sel = _estado == valor;
                  return ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _estado = valor),
                    selectedColor: nc.subastas.fill,
                    side: BorderSide(color: sel ? nc.subastas.fill : nc.border),
                    labelStyle: AppTypography.labelMedium(
                            color: sel ? nc.subastas.onFill : nc.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _Lista(
                    params: AuctionHistoryParams(
                        mode: 'participante', estado: _estado),
                    vacioTitulo: 'Aún no has ganado ni vas ganando subastas',
                    vacioTexto: 'Aquí aparecen las subastas donde tienes la '
                        'puja más alta o que ganaste.',
                  ),
                  _Lista(
                    params:
                        AuctionHistoryParams(mode: 'artista', estado: _estado),
                    vacioTitulo: 'No has abierto subastas',
                    vacioTexto: 'Abre una con una de tus obras disponibles.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista({
    required this.params,
    required this.vacioTitulo,
    required this.vacioTexto,
  });

  final AuctionHistoryParams params;
  final String vacioTitulo;
  final String vacioTexto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final async = ref.watch(auctionHistoryProvider(params));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ListView(children: [
        NcEmptyState(
          icon: Icons.cloud_off_rounded,
          accent: nc.tomateA,
          title: 'No pudimos cargar el historial',
          message: e.toString(),
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(auctionHistoryProvider(params)),
        ),
      ]),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(auctionHistoryProvider(params)),
        child: list.isEmpty
            ? ListView(children: [
                NcEmptyState(
                  icon: Icons.gavel_rounded,
                  accent: nc.subastas,
                  title: vacioTitulo,
                  message: vacioTexto,
                ),
              ])
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _Fila(auction: list[i]),
              ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fase = faseDe(auction);
    return NcCard(
      padding: const EdgeInsets.all(12),
      gradientBorder: false,
      onTap: () => context.push('/auctions/${auction.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: SubastaImage(url: auction.imagenUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auction.obraTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                const SizedBox(height: 4),
                FaseBadge(fase: fase),
                const SizedBox(height: 6),
                Text(formatCOP(auction.precioActual),
                    style: AppTypography.labelSemiBold(color: nc.subastas.ink)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: nc.textMuted),
        ],
      ),
    );
  }
}
