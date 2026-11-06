import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';
import '../widgets/subasta_ui.dart';

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
                  _Titulo(
                      'En vivo ahora',
                      enVivo.length == 1
                          ? '1 subasta'
                          : '${enVivo.length} subastas'),
                  for (final a in enVivo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _AuctionCard(auction: a, myId: myId),
                    ),
                ],
                if (proximas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _Titulo('Próximamente', null),
                  for (final a in proximas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _AuctionCard(auction: a, myId: myId),
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

class _Titulo extends StatelessWidget {
  const _Titulo(this.text, this.trailing);

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: AppTypography.displayBold(color: nc.textPrimary)),
          ),
          if (trailing != null)
            Text(trailing!,
                style: AppTypography.labelMedium(color: nc.textSecondary)),
        ],
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({required this.auction, required this.myId});

  final AuctionModel auction;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fase = faseDe(auction);
    final vasGanando =
        myId != null && auction.pujadorLiderId == myId && fase == FaseSubasta.enVivo;
    final hayPujas = auction.pujadorLiderId != null ||
        auction.precioActual > auction.precioBase;

    return NcCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/auctions/${auction.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SubastaImage(url: auction.imagenUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                Positioned(
                    left: 12, top: 12, child: FaseBadge(fase: fase, onImage: true)),
                if (vasGanando)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: nc.successA.fill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('VAS GANANDO',
                          style: AppTypography.caption(
                                  color: nc.successA.onFill)
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _TiempoPill(auction: auction, fase: fase),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auction.obraTitulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displaySemiBold(
                                  color: nc.textPrimary)
                              .copyWith(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(auction.artistaNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                              color: nc.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(hayPujas ? 'Puja actual' : 'Precio base',
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
                    Text(formatCOP(auction.precioActual),
                        style: AppTypography.price(color: nc.subastas.ink)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora de vidrio con la cuenta regresiva (cierre o inicio).
class _TiempoPill extends StatelessWidget {
  const _TiempoPill({required this.auction, required this.fase});

  final AuctionModel auction;
  final FaseSubasta fase;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final programada = fase == FaseSubasta.programada;
    return NcCountdown(
      target: programada ? auction.fechaInicio : auction.fechaCierre,
      builder: (_, r) {
        final urgente = !programada && r.inMinutes < 60;
        return Semantics(
          label: programada
              ? 'Empieza en ${NcCountdown.spoken(r)}'
              : 'Cierra en ${NcCountdown.spoken(r)}',
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                color: urgente
                    ? nc.enVivo.fill
                    : Colors.black.withValues(alpha: 0.45),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      programada
                          ? Icons.event_available_rounded
                          : Icons.timer_outlined,
                      size: 15,
                      color: urgente ? nc.enVivo.onFill : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${programada ? 'Empieza en' : 'Cierra en'} '
                      '${NcCountdown.format(r)}',
                      style: AppTypography.labelMedium(
                              color: urgente ? nc.enVivo.onFill : Colors.white)
                          .copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
