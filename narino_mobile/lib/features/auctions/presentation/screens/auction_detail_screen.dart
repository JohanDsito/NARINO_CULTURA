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
import 'auction_detail_screen/barra_puja.dart';
import 'auction_detail_screen/marcador_subasta.dart';
import 'auction_detail_screen/pujas_en_vivo.dart';

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
      final a = await ref
          .read(auctionsRepositoryProvider)
          .getDetail(widget.auctionId);
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
    final precio = toDouble(data['current_price']) ?? toDouble(data['amount']);
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
    final monto = double.tryParse(
        _bidCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.'));
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
                MarcadorSubasta(auction: a, fase: fase, voyGanando: voyGanando),
                const SizedBox(height: 16),
                ..._avisos(context, a, fase, soyVendedor, gane),
                const SizedBox(height: 8),
                PujasEnVivo(
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
          ? BarraPuja(
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
