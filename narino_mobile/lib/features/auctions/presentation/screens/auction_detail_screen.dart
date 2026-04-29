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

class AuctionDetailScreen extends ConsumerStatefulWidget {
  const AuctionDetailScreen({super.key, required this.auctionId});

  final int auctionId;

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
        if (data == null) return;
        _handleWsMessage(data);
      },
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );
  }

  void _handleWsMessage(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['event'])?.toString();

    if (type == null || type.isEmpty) {
      _applyServerState(data);
      return;
    }

    switch (type) {
      case 'auction_state':
        _applyServerState(data);
        break;
      case 'bid_update':
        _applyServerState(data);
        break;
      case 'auction_closed':
        _applyServerState(data, forceClosed: true);
        _timer?.cancel();
        _syncCountdown();
        break;
      default:
        _applyServerState(data);
        break;
    }
  }

  void _applyServerState(Map<String, dynamic> data,
      {bool forceClosed = false}) {
    final current = _auction;
    if (current == null) return;

    final rawAuction = data['auction'];
    final map = rawAuction is Map ? rawAuction.cast<String, dynamic>() : data;

    AuctionModel updated;
    try {
      updated = AuctionModel.fromJson(map);
    } catch (_) {
      updated = current;
    }

    final merged = current.copyWith(
      precioActual: updated.precioActual,
      totalPujas: updated.totalPujas,
      ultimasPujas: updated.ultimasPujas.isNotEmpty
          ? updated.ultimasPujas.take(5).toList()
          : current.ultimasPujas,
      estado: forceClosed ? 'cerrada' : updated.estado,
      ganadorNombre: updated.ganadorNombre ?? current.ganadorNombre,
      ganadorId: updated.ganadorId ?? current.ganadorId,
      orderId: updated.orderId ?? current.orderId,
      fechaCierre: updated.fechaCierre,
    );

    setState(() => _auction = merged);
    _syncCountdown();
  }

  void _syncCountdown() {
    final a = _auction;
    if (a == null) return;
    final now = DateTime.now();
    final diff = a.fechaCierre.difference(now);
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final a = _auction;
      if (a == null) return;
      if (a.estado != 'activa') return;
      _syncCountdown();
      if (_remaining == Duration.zero) {
        _timer?.cancel();
      }
    });
  }

  String _formatRemaining(Duration d) {
    final totalSeconds = d.inSeconds;
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool _isArtistOwner(AuctionModel auction,
      {required String myName, required int? myId}) {
    if (auction.artistaId != null && myId != null) {
      return auction.artistaId == myId;
    }
    final a = auction.artistaNombre.trim().toLowerCase();
    final b = myName.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b;
  }

  bool _isWinner(AuctionModel auction, {required int? myId}) {
    if (auction.ganadorId != null && myId != null) {
      return auction.ganadorId == myId;
    }
    return false;
  }

  Future<void> _placeBid() async {
    final auction = _auction;
    if (auction == null) return;
    if (auction.estado != 'activa') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta subasta ya no está activa.')),
      );
      return;
    }

    final me = await ref.read(profileRepositoryProvider).getMyProfile();
    if (!mounted) return;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar tu perfil.')),
      );
      return;
    }
    final myId = me.id;
    final myName = me.nombreArtistico;

    if (_isArtistOwner(auction, myName: myName, myId: myId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes pujar en tu propia subasta.')),
      );
      return;
    }

    final raw = _bidCtrl.text.trim().replaceAll(',', '.');
    final monto = double.tryParse(raw);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido.')),
      );
      return;
    }

    final min = auction.precioActual * 1.05;
    if (monto < min) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La puja debe superar al menos 5% el precio actual (mínimo \$${min.toStringAsFixed(0)}).',
          ),
        ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isBidding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auction = _auction;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.tierraProfunda),
        ),
      );
    }

    if (_error != null || auction == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: AppColors.obsidiana,
          foregroundColor: AppColors.oroClaro,
          title: Text(
            'Subasta',
            style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? 'No se pudo cargar la subasta.',
                  style: AppTypography.bodySmall(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
            onPressed: () => context.go('/auctions/history'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.tierraProfunda,
        onRefresh: () async {
          await _load();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (auction.estado != 'activa') _ClosedBanner(auction: auction),
            if (auction.imagenUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  auction.imagenUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: AppColors.bgCardLight,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child:
                    const Center(child: Icon(Icons.image_outlined, size: 52)),
              ),
            const SizedBox(height: 12),
            Text(
              auction.obraTitulo,
              style: AppTypography.displaySemiBold(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              auction.artistaNombre,
              style: AppTypography.bodySmall(color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 14),
            _StatCard(
              precioActual: auction.precioActual,
              totalPujas: auction.totalPujas,
              remaining: _remaining,
              estado: auction.estado,
              formatRemaining: _formatRemaining,
            ),
            const SizedBox(height: 14),
            Text(
              'Últimas pujas',
              style: AppTypography.labelSemiBold(
                  color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 10),
            _BidsList(bids: auction.ultimasPujas.take(5).toList()),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bidCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payments_outlined),
                labelText: 'Nueva puja',
                hintText: 'Ej: 300000',
              ),
              enabled: auction.estado == 'activa' && !_isBidding,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (auction.estado == 'activa' && !_isBidding)
                    ? _placeBid
                    : null,
                child: _isBidding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Pujar',
                        style: AppTypography.buttonText(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            _WinnerActions(
                auction: auction,
                isWinnerFn: _isWinner,
                isArtistFn: _isArtistOwner),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.precioActual,
    required this.totalPujas,
    required this.remaining,
    required this.estado,
    required this.formatRemaining,
  });

  final double precioActual;
  final int totalPujas;
  final Duration remaining;
  final String estado;
  final String Function(Duration d) formatRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio actual',
                  style: AppTypography.caption(color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${precioActual.toStringAsFixed(0)}',
                  style: AppTypography.displaySemiBold(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.borderLight),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pujas',
                  style: AppTypography.caption(color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalPujas',
                  style: AppTypography.labelSemiBold(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tiempo restante',
                  style: AppTypography.caption(color: AppColors.textMutedLight),
                ),
                const SizedBox(height: 4),
                Text(
                  estado == 'activa' ? formatRemaining(remaining) : '--:--:--',
                  style: AppTypography.bodyMedium(
                    color: (estado == 'activa' && remaining.inMinutes < 60)
                        ? AppColors.error
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BidsList extends StatelessWidget {
  const _BidsList({required this.bids});

  final List<AuctionBidModel> bids;

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          'Aún no hay pujas.',
          style: AppTypography.bodySmall(color: AppColors.textMutedLight),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: bids.asMap().entries.map((entry) {
          final i = entry.key;
          final bid = entry.value;
          return Container(
            decoration: BoxDecoration(
              border: i == bids.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                bid.bidderName,
                style:
                    AppTypography.bodySmall(color: AppColors.textPrimaryLight),
              ),
              trailing: Text(
                '\$${bid.amount.toStringAsFixed(0)}',
                style: AppTypography.labelSemiBold(
                    color: AppColors.tierraProfunda),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ClosedBanner extends ConsumerWidget {
  const _ClosedBanner({required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winner = auction.ganadorNombre;
    final hasWinner = winner != null && winner.trim().isNotEmpty;
    final winnerText = winner?.trim() ?? '';

    final text = hasWinner
        ? 'Ganador: $winnerText · Monto final \$${auction.precioActual.toStringAsFixed(0)}'
        : 'Sin pujas — subasta cerrada';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oroAndino,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium(color: AppColors.obsidiana),
      ),
    );
  }
}

class _WinnerActions extends ConsumerWidget {
  const _WinnerActions({
    required this.auction,
    required this.isWinnerFn,
    required this.isArtistFn,
  });

  final AuctionModel auction;
  final bool Function(AuctionModel auction, {required int? myId}) isWinnerFn;
  final bool Function(AuctionModel auction,
      {required String myName, required int? myId}) isArtistFn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (auction.estado == 'activa') return const SizedBox.shrink();

    return FutureBuilder(
      future: ref.read(profileRepositoryProvider).getMyProfile(),
      builder: (context, snapshot) {
        final me = snapshot.data;
        final myId = me?.id;
        final myName = me?.nombreArtistico ?? '';

        final isWinner = isWinnerFn(auction, myId: myId);
        final isArtist = me == null
            ? false
            : isArtistFn(auction, myName: myName, myId: myId);

        if (isWinner) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                final orderId = auction.orderId;
                if (orderId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se encontró la orden para pago.'),
                    ),
                  );
                  return;
                }
                context.go('/marketplace/checkout?orderId=$orderId');
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                'Completar pago',
                style: AppTypography.buttonText(color: Colors.white),
              ),
            ),
          );
        }

        if (isArtist) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              'Tu subasta cerró. Revisa el resultado en tu historial.',
              style:
                  AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
