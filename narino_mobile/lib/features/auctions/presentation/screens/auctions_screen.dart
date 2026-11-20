import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/auctions_provider.dart';
import '../widgets/subasta_ui.dart';
import 'auctions_screen/auction_card.dart';
import 'auctions_screen/subastas_titulo.dart';

/// Subastas activas (acento oro; tomate para "en vivo" y urgencia).
class AuctionsScreen extends ConsumerWidget {
  const AuctionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final async = ref.watch(auctionsProvider);
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final myId = ref.watch(currentUserIdProvider).valueOrNull;
    final canCreate = role == 'artista' || role == 'admin';
    final top = MediaQuery.paddingOf(context).top + NcGlassHeader.contentHeight;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: NcGlassHeader(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LiveDot(color: nc.enVivo.ink, size: 7),
                const SizedBox(width: 6),
                Text('PUJAS EN TIEMPO REAL',
                    style: AppTypography.caption(color: nc.enVivo.ink)
                        .copyWith(letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 2),
            Text('Subastas',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
          ],
        ),
        actions: [
          NcIconButton(
            icon: Icons.history_rounded,
            tooltip: 'Mi historial',
            onPressed: () => context.push('/auctions/history'),
          ),
          if (canCreate)
            NcIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Abrir subasta',
              onPressed: () => context.push('/auctions/new'),
            ),
        ],
      ),
      body: RefreshIndicator(
        edgeOffset: top,
        onRefresh: () => ref.read(auctionsProvider.notifier).loadActive(),
        child: async.when(
          loading: () => ListView(children: [
            SizedBox(height: top + 80),
            const Center(child: CircularProgressIndicator()),
          ]),
          error: (e, _) => ListView(children: [
            SizedBox(height: top),
            NcEmptyState(
              icon: Icons.cloud_off_rounded,
              accent: nc.tomateA,
              title: 'No pudimos cargar las subastas',
              message: e.toString(),
              actionLabel: 'Reintentar',
              onAction: () => ref.read(auctionsProvider.notifier).loadActive(),
            ),
          ]),
          data: (list) {
            final enVivo = list
                .where((a) => faseDe(a, now: now) == FaseSubasta.enVivo)
                .toList();
            final proximas = list
                .where((a) => faseDe(a, now: now) == FaseSubasta.programada)
                .toList()
              ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

            if (enVivo.isEmpty && proximas.isEmpty) {
              return ListView(children: [
                SizedBox(height: top),
                NcEmptyState(
                  icon: Icons.gavel_rounded,
                  accent: nc.subastas,
                  title: 'No hay subastas en este momento',
                  message: canCreate
                      ? 'Abre una subasta con una de tus obras: un '
                          'administrador la revisa y sale en vivo.'
                      : 'Vuelve pronto: aquí verás las pujas en tiempo real.',
                  actionLabel: canCreate ? 'Abrir una subasta' : null,
                  onAction:
                      canCreate ? () => context.push('/auctions/new') : null,
                ),
              ]);
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(16, top + 16, 16, 24),
              children: [
                if (enVivo.isNotEmpty) ...[
                  SubastasTitulo(
                      'En vivo ahora',
                      enVivo.length == 1
                          ? '1 subasta'
                          : '${enVivo.length} subastas'),
                  for (final a in enVivo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AuctionCard(auction: a, myId: myId),
                    ),
                ],
                if (proximas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const SubastasTitulo('Próximamente', null),
                  for (final a in proximas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AuctionCard(auction: a, myId: myId),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
