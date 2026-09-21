import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/auction_ws_client.dart';
import '../../domain/auction_bid_model.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';
import 'auction_detail_screen/auction_image.dart';
import 'auction_detail_screen/bid_button.dart';
import 'auction_detail_screen/bid_field.dart';
import 'auction_detail_screen/bids_list.dart';
import 'auction_detail_screen/closed_banner.dart';
import 'auction_detail_screen/error_scaffold.dart';
import 'auction_detail_screen/owner_auction_notice.dart';
import 'auction_detail_screen/stat_card.dart';
import 'auction_detail_screen/winner_actions.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class AuctionDetailScreen extends ConsumerStatefulWidget {
  const AuctionDetailScreen({super.key, required this.auctionId});

  final String auctionId;

  @override
  ConsumerState<AuctionDetailScreen> createState() =>
      _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  final _bidCtrl = TextEditingController();
  final _ws = AuctionWsClient();

  AuctionModel? _auction;
  bool _isLoading = true;
  bool _isBidding = false;
  String? _error;
  bool _isOwner = false;

  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bidCtrl.dispose();
    _ws.close();
    super.dispose();
  }

  // ─── Carga y WebSocket ────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auction = await ref
          .read(auctionsRepositoryProvider)
          .getDetail(widget.auctionId);
      if (!mounted) return;
      setState(() {
        _auction = auction;
        _isLoading = false;
      });
      _syncCountdown();
      _startCountdown();
      await _connectWs();
      _checkOwnership(auction);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _connectWs() async {
    await _ws.connect(widget.auctionId);
    _ws.stream?.listen(
      (msg) {
        final data = _ws.tryDecodeMessage(msg);
        if (data != null) _handleWsMessage(data);
      },
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );
  }

  void _handleWsMessage(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['event'])?.toString();
    // Backend emits 'closed' on close, 'bid' on new bid, 'snapshot' on connect
    final forceClosed = type == 'closed' || type == 'auction_closed';
    _applyServerState(data, forceClosed: forceClosed);
    if (forceClosed) _timer?.cancel();
  }

  void _applyServerState(Map<String, dynamic> data,
      {bool forceClosed = false}) {
    final current = _auction;
    if (current == null) return;

    // WS messages are flat (bid/snapshot), not full auction objects.
    // Extract fields directly instead of running full fromJson.
    double? newPrecio = _parseDouble(data['current_price']) ??
        _parseDouble(data['amount']);

    DateTime? newCierre =
        DateTime.tryParse(data['ends_at']?.toString() ?? '');

    // Fallback: try nested 'auction' map (future-proofing)
    final rawAuction = data['auction'];
    if (rawAuction is Map) {
      final nested = rawAuction.cast<String, dynamic>();
      newPrecio ??= _parseDouble(nested['current_price']);
      newCierre ??= DateTime.tryParse(nested['ends_at']?.toString() ?? '');
    }

    // Bids list from WS (if included)
    final bidsRaw = data['bids'] ?? data['ultimas_pujas'];
    final newBids = bidsRaw is List
        ? bidsRaw
            .whereType<Map>()
            .map((e) =>
                AuctionBidModel.fromJson(e.cast<String, dynamic>()))
            .take(5)
            .toList()
        : null;

    // Winner from close event
    final winnerId = data['winner_id']?.toString();

    final merged = current.copyWith(
      precioActual: newPrecio ?? current.precioActual,
      fechaCierre: newCierre ?? current.fechaCierre,
      totalPujas: newBids != null ? newBids.length : current.totalPujas,
      ultimasPujas: newBids ?? current.ultimasPujas,
      estado: forceClosed ? 'cerrada' : current.estado,
      ganadorId: winnerId ?? current.ganadorId,
    );

    setState(() => _auction = merged);
    _syncCountdown();
  }

  static double? _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // ─── Countdown ────────────────────────────────────────────────────────────

  void _syncCountdown() {
    final a = _auction;
    if (a == null) return;
    final diff = a.fechaCierre.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_auction?.estado != 'activa') return;
      _syncCountdown();
      if (_remaining == Duration.zero) _timer?.cancel();
    });
  }

  // ─── Verificar propiedad ──────────────────────────────────────────────────

  Future<void> _checkOwnership(AuctionModel auction) async {
    try {
      final me = await ref.read(profileRepositoryProvider).getMyProfile();
      if (!mounted || me == null) return;
      final isOwner =
          _isArtistOwner(auction, myName: me.nombreArtistico, myId: me.id);
      setState(() => _isOwner = isOwner);
    } catch (_) {}
  }

  // ─── Permisos ─────────────────────────────────────────────────────────────

  static bool _isArtistOwner(AuctionModel auction,
      {required String myName, required String? myId}) {
    if (auction.artistaId != null && myId != null) {
      return auction.artistaId == myId;
    }
    final a = auction.artistaNombre.trim().toLowerCase();
    final b = myName.trim().toLowerCase();
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  static bool _isWinner(AuctionModel auction, {required String? myId}) {
    return auction.ganadorId != null &&
        myId != null &&
        auction.ganadorId == myId;
  }

  // ─── Puja ─────────────────────────────────────────────────────────────────

  Future<void> _placeBid() async {
    final auction = _auction;
    if (auction == null) return;

    if (auction.estado != 'activa') {
      _showSnackBar('Esta subasta ya no está activa.');
      return;
    }

    final me = await ref.read(profileRepositoryProvider).getMyProfile();
    if (!mounted) return;
    if (me == null) {
      _showSnackBar('No se pudo cargar tu perfil.');
      return;
    }

    if (_isArtistOwner(auction, myName: me.nombreArtistico, myId: me.id)) {
      _showSnackBar('No puedes pujar en tu propia subasta.');
      return;
    }

    final monto = double.tryParse(_bidCtrl.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      _showSnackBar('Ingresa un monto válido.');
      return;
    }

    final min = auction.precioActual * 1.05;
    if (monto < min) {
      _showSnackBar(
        'La puja debe superar al menos 5% el precio actual (mínimo \$${min.toStringAsFixed(0)}).',
      );
      return;
    }

    setState(() => _isBidding = true);
    try {
      await ref
          .read(auctionsRepositoryProvider)
          .bid(auctionId: auction.id, monto: monto);
      _bidCtrl.clear();
    } catch (e) {
      if (mounted) _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isBidding = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
        ),
      );
    }

    if (_error != null || _auction == null) {
      return ErrorScaffold(error: _error, onRetry: _load);
    }

    final auction = _auction!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Subasta',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.oroClaro),
            onPressed: () => context.push('/auctions/history'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (auction.estado != 'activa') ...[
              ClosedBanner(auction: auction),
              const SizedBox(height: 12),
            ],
            AuctionImage(imageUrl: auction.imagenUrl),
            const SizedBox(height: 14),
            Text(
              auction.obraTitulo,
              style: AppTypography.displaySemiBold(color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              auction.artistaNombre,
              style: AppTypography.bodySmall(color: textMuted),
            ),
            const SizedBox(height: 16),
            StatCard(
              precioActual: auction.precioActual,
              totalPujas: auction.totalPujas,
              remaining: _remaining,
              estado: auction.estado,
            ),
            const SizedBox(height: 16),
            Text(
              'Últimas pujas',
              style: AppTypography.labelSemiBold(color: textPrimary),
            ),
            const SizedBox(height: 10),
            BidsList(bids: auction.ultimasPujas.take(5).toList()),
            const SizedBox(height: 18),
            if (auction.estado == 'activa') ...[
              if (_isOwner)
                const OwnerAuctionNotice()
              else ...[
                BidField(
                  controller: _bidCtrl,
                  isBidding: _isBidding,
                  minPrice: auction.precioActual * 1.05,
                ),
                const SizedBox(height: 12),
                BidButton(isBidding: _isBidding, onPressed: _placeBid),
              ],
              const SizedBox(height: 18),
            ],
            WinnerActions(
              auction: auction,
              isWinnerFn: _isWinner,
              isArtistFn: _isArtistOwner,
            ),
          ],
        ),
      ),
    );
  }
}
