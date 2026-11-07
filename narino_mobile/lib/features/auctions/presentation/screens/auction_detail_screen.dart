import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../data/auction_ws_client.dart';
import '../../domain/auction_bid_model.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';
import '../widgets/subasta_ui.dart';

/// Detalle de subasta en tiempo real (WebSocket): precio, cuenta regresiva,
/// pujas en vivo y barra fija para pujar.
class AuctionDetailScreen extends ConsumerStatefulWidget {
  const AuctionDetailScreen({super.key, required this.auctionId, this.ws});

  final String auctionId;

  /// Inyectable para pruebas; por defecto el cliente real.
  final AuctionWsClient? ws;

  @override
  ConsumerState<AuctionDetailScreen> createState() =>
      _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  final _bidCtrl = TextEditingController();
  late final AuctionWsClient _ws = widget.ws ?? AuctionWsClient();

  AuctionModel? _auction;
  bool _isLoading = true;
  bool _isBidding = false;
  String? _error;

  /// Pujas recibidas en vivo desde que se abrió la pantalla (resalta la última).
  int _pujasEnVivo = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bidCtrl.dispose();
    _ws.close();
    super.dispose();
  }

  // ─── Datos y WebSocket ────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = _auction == null;
      _error = null;
    });
    try {
      final a =
          await ref.read(auctionsRepositoryProvider).getDetail(widget.auctionId);
      if (!mounted) return;
      setState(() {
        _auction = a;
        _isLoading = false;
      });
      await _connectWs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _connectWs() async {
    try {
      await _ws.connect(widget.auctionId);
      _ws.stream?.listen(
        (msg) {
          final data = _ws.tryDecodeMessage(msg);
          if (data != null) _onMessage(data);
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // Sin tiempo real: la pantalla sigue funcionando con "deslizar para
      // actualizar".
    }
  }

  /// Mensajes: `connected`, `snapshot`, `bid_placed`, `auction_closed`.
  void _onMessage(Map<String, dynamic> data) {
    final current = _auction;
    if (current == null || !mounted) return;
    final type = (data['type'] ?? data['event'])?.toString();
    if (type == 'connected') return;

    double? toDouble(Object? v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');
    final precio =
        toDouble(data['current_price']) ?? toDouble(data['amount']);
    final cierre = DateTime.tryParse(data['ends_at']?.toString() ?? '');
    final status = data['status']?.toString().toLowerCase();
    final cerrada = type == 'auction_closed' ||
        (type == 'snapshot' && status != null && status != 'activa');

    var pujas = current.ultimasPujas;
    var total = current.totalPujas;
    if (type == 'bid_placed') {
      final monto = toDouble(data['amount']);
      if (monto != null) {
        pujas = [
          AuctionBidModel(
            bidderName: data['bidder_name']?.toString() ?? 'Alguien',
            amount: monto,
            createdAt: DateTime.now(),
          ),
          ...current.ultimasPujas,
        ].take(8).toList();
        total = current.totalPujas + 1;
        _pujasEnVivo++;
        HapticFeedback.selectionClick();
      }
    }

    final winner = data['winner_id']?.toString();
    setState(() {
      _auction = current.copyWith(
        precioActual: precio ?? current.precioActual,
        fechaCierre: cierre ?? current.fechaCierre,
        ultimasPujas: pujas,
        totalPujas: total,
        estado: cerrada ? 'cerrada' : (status ?? current.estado),
        ganadorId: (winner != null && winner != 'null') ? winner : null,
        pujadorLiderId: data['highest_bidder_id']?.toString() ??
            data['bidder_id']?.toString(),
      );
    });
    // Al cerrar, el detalle REST trae `payment_order_id` para el ganador.
    if (type == 'auction_closed') _load();
  }

  // ─── Pujar ────────────────────────────────────────────────────────────────

  Future<void> _placeBid() async {
    final a = _auction;
    if (a == null) return;
    FocusScope.of(context).unfocus();
    final monto =
        double.tryParse(_bidCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    // Regla del backend: la puja debe ser mayor al precio actual.
    if (monto == null || monto <= a.precioActual) {
      _snack('Tu puja debe ser mayor a ${formatCOP(a.precioActual)}.');
      return;
    }
    setState(() => _isBidding = true);
    try {
      await ref
          .read(auctionsRepositoryProvider)
          .bid(auctionId: a.id, monto: monto);
      _bidCtrl.clear();
      HapticFeedback.mediumImpact();
      _snack('¡Puja enviada por ${formatCOP(monto)}!');
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _isBidding = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final myId = ref.watch(currentUserIdProvider).valueOrNull;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _auction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subasta')),
        body: ListView(children: [
          NcEmptyState(
            icon: Icons.cloud_off_rounded,
            accent: nc.tomateA,
            title: 'No pudimos cargar la subasta',
            message: _error ?? 'Intenta de nuevo.',
            actionLabel: 'Reintentar',
            onAction: _load,
          ),
        ]),
      );
    }

    final a = _auction!;
    final fase = faseDe(a);
    final soyVendedor = myId != null && a.artistaId == myId;
    final voyGanando = myId != null && a.pujadorLiderId == myId;
    final gane = myId != null && a.ganadorId == myId;
    final puedePujar = fase == FaseSubasta.enVivo && !soyVendedor;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              backgroundColor: nc.bg,
              surfaceTintColor: Colors.transparent,
              shape: const Border(),
              automaticallyImplyLeading: false,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: GlassCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Volver',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              actions: [
                GlassCircleButton(
                  icon: Icons.history_rounded,
                  tooltip: 'Mi historial',
                  onPressed: () => context.push('/auctions/history'),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: a.obraId.isEmpty
                          ? null
                          : () => context.push('/artworks/${a.obraId}'),
                      child: SubastaImage(url: a.imagenUrl),
                    ),
                    Positioned(
                        left: 16,
                        bottom: 44,
                        child: FaseBadge(fase: fase, onImage: true)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -1,
                      child: Container(
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: nc.bg,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28)),
                        ),
                        child: const NcSerpentina(width: 44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.list(children: [
                Text(a.obraTitulo,
                    style: AppTypography.displayBlack(color: nc.textPrimary)
                        .copyWith(fontSize: 26, height: 1.15)),
                const SizedBox(height: 4),
                Text('de ${a.artistaNombre}',
                    style: AppTypography.bodyMedium(color: nc.textSecondary)),
                const SizedBox(height: 18),
                _Marcador(auction: a, fase: fase, voyGanando: voyGanando),
                const SizedBox(height: 16),
                ..._avisos(context, a, fase, soyVendedor, gane),
                const SizedBox(height: 8),
                _PujasEnVivo(
                  pujas: a.ultimasPujas,
                  resaltar: _pujasEnVivo > 0,
                  enVivo: fase == FaseSubasta.enVivo,
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: puedePujar
          ? _BarraPuja(
              controller: _bidCtrl,
              precioActual: a.precioActual,
              loading: _isBidding,
              onPujar: _placeBid,
            )
          : null,
    );
  }

  List<Widget> _avisos(BuildContext context, AuctionModel a, FaseSubasta fase,
      bool soyVendedor, bool gane) {
    final nc = context.nc;
    Widget gap(Widget w) =>
        Padding(padding: const EdgeInsets.only(bottom: 12), child: w);

    return [
      if (fase == FaseSubasta.pendiente)
        gap(NcBanner(
          accent: nc.oroA,
          icon: Icons.hourglass_top_rounded,
          message: soyVendedor
              ? 'Tu subasta está en revisión. Un administrador la aprobará '
                  'antes de que salga en vivo.'
              : 'Esta subasta aún no ha sido aprobada.',
        )),
      if (fase == FaseSubasta.programada)
        gap(NcBanner(
          accent: nc.azulA,
          icon: Icons.event_available_rounded,
          message: 'Las pujas se abren el '
              '${a.fechaInicio.day}/${a.fechaInicio.month} a las '
              '${a.fechaInicio.hour.toString().padLeft(2, '0')}:'
              '${a.fechaInicio.minute.toString().padLeft(2, '0')}.',
        )),
      if (fase == FaseSubasta.cancelada)
        gap(NcBanner(
          accent: nc.tomateA,
          icon: Icons.block_rounded,
          message: 'Esta subasta fue cancelada.',
        )),
      if (soyVendedor && fase == FaseSubasta.enVivo)
        gap(NcBanner(
          accent: nc.subastas,
          icon: Icons.visibility_outlined,
          message: 'Es tu subasta: puedes seguir las pujas en vivo, pero no '
              'pujar.',
        )),
      if (fase == FaseSubasta.cerrada && gane)
        gap(NcCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              NcAccentIcon(
                  icon: Icons.emoji_events_outlined,
                  accent: nc.subastas,
                  size: 60,
                  glow: true),
              const SizedBox(height: 12),
              Text('¡Ganaste la subasta!',
                  style: AppTypography.displaySemiBold(color: nc.textPrimary)),
              const SizedBox(height: 4),
              Text('Completa el pago para recibir tu obra.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: nc.textSecondary)),
              const SizedBox(height: 16),
              NcPrimaryButton(
                label: 'Pagar ${formatCOP(a.precioActual)}',
                icon: Icons.credit_card_rounded,
                onPressed: a.orderId == null
                    ? () => _snack('Estamos generando tu orden de pago. '
                        'Desliza hacia abajo en unos segundos.')
                    : () => context
                        .push('/marketplace/checkout?orderId=${a.orderId}'),
              ),
            ],
          ),
        )),
      if (fase == FaseSubasta.cerrada && !gane)
        gap(NcBanner(
          accent: nc.subastas,
          icon: Icons.flag_outlined,
          message: a.ganadorId == null
              ? 'La subasta terminó sin pujas.'
              : soyVendedor
                  ? '¡Tu obra se subastó por ${formatCOP(a.precioActual)}!'
                  : 'La subasta terminó en ${formatCOP(a.precioActual)}.',
        )),
    ];
  }
}

/// Precio actual + cuenta regresiva + estado de liderazgo.
class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.auction,
    required this.fase,
    required this.voyGanando,
  });

  final AuctionModel auction;
  final FaseSubasta fase;
  final bool voyGanando;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = auction;
    final hayPujas = a.pujadorLiderId != null || a.precioActual > a.precioBase;
    final mostrarTiempo =
        fase == FaseSubasta.enVivo || fase == FaseSubasta.programada;

    return NcCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fase == FaseSubasta.cerrada
                          ? 'PRECIO FINAL'
                          : (hayPujas ? 'PUJA ACTUAL' : 'PRECIO BASE'),
                      style: AppTypography.kicker(color: nc.oroA.ink),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (c, anim) => ScaleTransition(
                          scale: Tween(begin: 1.15, end: 1.0).animate(anim),
                          child: FadeTransition(opacity: anim, child: c)),
                      child: Text(
                        formatCOP(a.precioActual),
                        key: ValueKey(a.precioActual),
                        style: AppTypography.displayBlack(color: nc.subastas.ink)
                            .copyWith(fontSize: 32),
                      ),
                    ),
                    if (hayPujas && fase != FaseSubasta.cerrada)
                      Text('Base ${formatCOP(a.precioBase)}',
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
                  ],
                ),
              ),
              if (voyGanando && fase == FaseSubasta.enVivo)
                NcStatusPill(
                  label: 'Vas ganando',
                  accent: nc.successA,
                  filled: true,
                  icon: Icons.emoji_events_outlined,
                ),
            ],
          ),
          if (mostrarTiempo) ...[
            const SizedBox(height: 16),
            const NcSerpentina(width: double.infinity, height: 3),
            const SizedBox(height: 16),
            NcCountdown(
              target: fase == FaseSubasta.programada
                  ? a.fechaInicio
                  : a.fechaCierre,
              builder: (_, r) => _Segmentos(
                remaining: r,
                titulo: fase == FaseSubasta.programada
                    ? 'Empieza en'
                    : 'Cierra en',
                urgente: fase == FaseSubasta.enVivo && r.inMinutes < 60,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segmentos extends StatelessWidget {
  const _Segmentos({
    required this.remaining,
    required this.titulo,
    required this.urgente,
  });

  final Duration remaining;
  final String titulo;
  final bool urgente;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final accent = urgente ? nc.enVivo : nc.subastas;
    final partes = <(int, String)>[
      (remaining.inDays, 'días'),
      (remaining.inHours.remainder(24), 'horas'),
      (remaining.inMinutes.remainder(60), 'min'),
      (remaining.inSeconds.remainder(60), 'seg'),
    ];
    return Semantics(
      label: '$titulo ${NcCountdown.spoken(remaining)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: AppTypography.labelMedium(color: nc.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < partes.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: urgente ? accent.fill : accent.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          partes[i].$1.toString().padLeft(2, '0'),
                          style: AppTypography.displaySemiBold(
                                  color: urgente ? accent.onFill : accent.ink)
                              .copyWith(
                            fontSize: 22,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(partes[i].$2,
                            style: AppTypography.caption(
                                color: urgente
                                    ? accent.onFill
                                    : nc.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PujasEnVivo extends StatelessWidget {
  const _PujasEnVivo({
    required this.pujas,
    required this.resaltar,
    required this.enVivo,
  });

  final List<AuctionBidModel> pujas;
  final bool resaltar;
  final bool enVivo;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final palette = [nc.tomateA, nc.naranjaA, nc.oroA, nc.magentaA, nc.azulA];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Pujas en vivo',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            if (enVivo) ...[
              const SizedBox(width: 8),
              LiveDot(color: nc.enVivo.ink),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Aquí aparecen las pujas que llegan mientras tienes la subasta '
          'abierta.',
          style: AppTypography.bodySmall(color: nc.textSecondary),
        ),
        const SizedBox(height: 12),
        if (pujas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nc.itemFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: nc.border),
            ),
            child: Text(
              enVivo
                  ? 'Todavía no llegan pujas nuevas. ¡Puedes ser la primera '
                      'persona en pujar!'
                  : 'No hay pujas para mostrar.',
              style: AppTypography.bodyMedium(color: nc.textSecondary),
            ),
          )
        else
          for (var i = 0; i < pujas.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: i == 0 && resaltar ? nc.subastas.tint : nc.itemFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: i == 0 && resaltar
                        ? nc.subastas.fill.withValues(alpha: 0.5)
                        : nc.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: palette[i % palette.length].fill,
                    child: Text(
                      pujas[i].bidderName.isNotEmpty
                          ? pujas[i].bidderName.characters.first.toUpperCase()
                          : '?',
                      style: AppTypography.labelSemiBold(
                              color: palette[i % palette.length].onFill)
                          .copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        pujas[i].esMia ? 'Tú' : pujas[i].bidderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSemiBold(
                                color: nc.textPrimary)
                            .copyWith(fontSize: 14)),
                  ),
                  Text(formatCOP(pujas[i].amount),
                      style: AppTypography.labelSemiBold(
                          color: i == 0 ? nc.subastas.ink : nc.textSecondary)),
                ],
              ),
            ),
      ],
    );
  }
}

/// Barra fija para pujar con montos sugeridos (+5 %, +10 %, +20 %).
class _BarraPuja extends StatelessWidget {
  const _BarraPuja({
    required this.controller,
    required this.precioActual,
    required this.loading,
    required this.onPujar,
  });

  final TextEditingController controller;
  final double precioActual;
  final bool loading;
  final VoidCallback onPujar;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    double redondear(double v) => (v / 1000).ceil() * 1000;
    final sugeridos = [1.05, 1.10, 1.20]
        .map((f) => redondear(precioActual * f))
        .toSet()
        .toList();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: nc.bgGlass,
            border: Border(top: BorderSide(color: nc.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final s in sugeridos) ...[
                    Expanded(
                      child: NcPressable(
                        onTap: () =>
                            controller.text = s.toStringAsFixed(0),
                        semanticLabel: 'Pujar ${formatCOP(s)}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: nc.subastas.tint,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color:
                                    nc.subastas.fill.withValues(alpha: 0.45)),
                          ),
                          child: Text(formatCOP(s),
                              style: AppTypography.labelMedium(
                                      color: nc.subastas.ink)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    if (s != sugeridos.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !loading,
                      onSubmitted: (_) => onPujar(),
                      decoration: InputDecoration(
                        hintText: 'Más de ${formatCOP(precioActual)}',
                        prefixText: r'$ ',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide(color: nc.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide:
                              BorderSide(color: nc.subastas.fill, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  NcPrimaryButton(
                    label: 'Pujar',
                    icon: Icons.gavel_rounded,
                    expand: false,
                    loading: loading,
                    onPressed: onPujar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
