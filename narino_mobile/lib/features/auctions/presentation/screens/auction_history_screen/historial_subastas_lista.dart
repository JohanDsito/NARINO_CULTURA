import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../providers/auctions_provider.dart';
import 'historial_subasta_fila.dart';

class HistorialSubastasLista extends ConsumerWidget {
  const HistorialSubastasLista({
    super.key,
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
                itemBuilder: (_, i) => HistorialSubastaFila(
                  auction: list[i],
                  participante: params.mode == 'participante',
                ),
              ),
      ),
    );
  }
}
