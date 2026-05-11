import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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

// ─── Pantalla principal ───────────────────────────────────────────────────────

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
    final forceClosed =
        type != null && type.isNotEmpty && type == 'auction_closed';
    _applyServerState(data, forceClosed: forceClosed);
    if (forceClosed) _timer?.cancel();
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

  static String _formatRemaining(Duration d) {
    final h = (d.inSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((d.inSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ─── Permisos ─────────────────────────────────────────────────────────────

  static bool _isArtistOwner(AuctionModel auction,
      {required String myName, required int? myId}) {
    if (auction.artistaId != null && myId != null) {
      return auction.artistaId == myId;
    }
    final a = auction.artistaNombre.trim().toLowerCase();
    final b = myName.trim().toLowerCase();
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }

  static bool _isWinner(AuctionModel auction, {required int? myId}) {
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
              color: AppColors.tierraProfunda, strokeWidth: 2),
        ),
      );
    }

    if (_error != null || _auction == null) {
      return _ErrorScaffold(error: _error, onRetry: _load);
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
            onPressed: () => context.go('/auctions/history'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.tierraProfunda,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (auction.estado != 'activa') ...[
              _ClosedBanner(auction: auction),
              const SizedBox(height: 12),
            ],
            _AuctionImage(imageUrl: auction.imagenUrl),
            const SizedBox(height: 14),
            Text(
              auction.obraTitulo,
              style: AppTypography.displaySemiBold(
                  color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              auction.artistaNombre,
              style: AppTypography.bodySmall(color: AppColors.textMutedLight),
            ),
            const SizedBox(height: 16),
            _StatCard(
              precioActual: auction.precioActual,
              totalPujas: auction.totalPujas,
              remaining: _remaining,
              estado: auction.estado,
            ),
            const SizedBox(height: 16),
            Text(
              'Últimas pujas',
              style: AppTypography.labelSemiBold(
                  color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 10),
            _BidsList(bids: auction.ultimasPujas.take(5).toList()),
            const SizedBox(height: 18),
            if (auction.estado == 'activa') ...[
              _BidField(
                controller: _bidCtrl,
                isBidding: _isBidding,
                minPrice: auction.precioActual * 1.05,
              ),
              const SizedBox(height: 12),
              _BidButton(isBidding: _isBidding, onPressed: _placeBid),
              const SizedBox(height: 18),
            ],
            _WinnerActions(
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

// ─── Vistas de estado ─────────────────────────────────────────────────────────

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.textMutedLight),
              const SizedBox(height: 14),
              Text(
                error ?? 'No se pudo cargar la subasta.',
                style: AppTypography.bodySmall(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Imagen de la subasta ─────────────────────────────────────────────────────

class _AuctionImage extends StatelessWidget {
  const _AuctionImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => const _ImagePlaceholder(height: 220),
              errorWidget: (_, __, ___) => const _ImageError(height: 220),
            )
          : const _ImageError(height: 220),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.bgSubtleLight,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined,
            size: 52, color: AppColors.textMutedLight),
      ),
    );
  }
}

// ─── Card de estadísticas ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.precioActual,
    required this.totalPujas,
    required this.remaining,
    required this.estado,
  });

  final double precioActual;
  final int totalPujas;
  final Duration remaining;
  final String estado;

  static String _formatRemaining(Duration d) {
    final h = (d.inSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((d.inSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get _isUrgent => estado == 'activa' && remaining.inMinutes < 60;

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
            child: _StatColumn(
              label: 'Precio actual',
              value: '\$${precioActual.toStringAsFixed(0)}',
              valueStyle: AppTypography.displaySemiBold(
                  color: AppColors.textPrimaryLight),
            ),
          ),
          Container(width: 1, height: 56, color: AppColors.borderLight),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatColumn(
                  label: 'Pujas',
                  value: '$totalPujas',
                  valueStyle: AppTypography.labelSemiBold(
                      color: AppColors.textPrimaryLight),
                ),
                const SizedBox(height: 12),
                _StatColumn(
                  label: 'Tiempo restante',
                  value: estado == 'activa'
                      ? _formatRemaining(remaining)
                      : '--:--:--',
                  valueStyle: AppTypography.bodyMedium(
                    color: _isUrgent
                        ? AppColors.error
                        : AppColors.textSecondaryLight,
                  ),
                  icon: _isUrgent
                      ? const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.error)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueStyle,
    this.icon,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption(color: AppColors.textMutedLight)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 4)],
            Text(value, style: valueStyle),
          ],
        ),
      ],
    );
  }
}

// ─── Lista de pujas ───────────────────────────────────────────────────────────

class _BidsList extends StatelessWidget {
  const _BidsList({required this.bids});

  final List<AuctionBidModel> bids;

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.gavel_outlined,
                size: 18, color: AppColors.textMutedLight),
            const SizedBox(width: 8),
            Text(
              'Aún no hay pujas. ¡Sé el primero!',
              style: AppTypography.bodySmall(color: AppColors.textMutedLight),
            ),
          ],
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
          final isLast = i == bids.length - 1;
          final isTop = i == 0;

          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: ListTile(
              dense: true,
              leading: isTop
                  ? const Icon(Icons.emoji_events_outlined,
                      size: 18, color: AppColors.oroAndino)
                  : Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '${i + 1}',
                        style: AppTypography.caption(
                            color: AppColors.textMutedLight),
                      ),
                    ),
              title: Text(
                bid.bidderName,
                style:
                    AppTypography.bodySmall(color: AppColors.textPrimaryLight),
              ),
              trailing: Text(
                '\$${bid.amount.toStringAsFixed(0)}',
                style: AppTypography.labelSemiBold(
                    color:
                        isTop ? AppColors.oroAndino : AppColors.tierraProfunda),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Campo y botón de puja ────────────────────────────────────────────────────

class _BidField extends StatelessWidget {
  const _BidField({
    required this.controller,
    required this.isBidding,
    required this.minPrice,
  });

  final TextEditingController controller;
  final bool isBidding;
  final double minPrice;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: !isBidding,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.payments_outlined),
        labelText: 'Nueva puja',
        hintText: 'Mín. \$${minPrice.toStringAsFixed(0)}',
      ),
    );
  }
}

class _BidButton extends StatelessWidget {
  const _BidButton({required this.isBidding, required this.onPressed});

  final bool isBidding;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isBidding ? null : onPressed,
        icon: isBidding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.gavel_outlined),
        label: Text(
          isBidding ? 'Enviando...' : 'Pujar',
          style: AppTypography.buttonText(color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Banner de subasta cerrada ────────────────────────────────────────────────

class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner({required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    final winner = auction.ganadorNombre?.trim() ?? '';
    final hasWinner = winner.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.oroAndino,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.obsidiana, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasWinner
                  ? 'Ganador: $winner · Final \$${auction.precioActual.toStringAsFixed(0)}'
                  : 'Sin pujas — subasta cerrada',
              style: AppTypography.bodyMedium(color: AppColors.obsidiana),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Acciones del ganador / artista ──────────────────────────────────────────

class _WinnerActions extends ConsumerWidget {
  const _WinnerActions({
    required this.auction,
    required this.isWinnerFn,
    required this.isArtistFn,
  });

  final AuctionModel auction;
  final bool Function(AuctionModel, {required int? myId}) isWinnerFn;
  final bool Function(AuctionModel,
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
                        content: Text('No se encontró la orden para pago.')),
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
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.textMutedLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu subasta cerró. Revisa el resultado en tu historial.',
                    style: AppTypography.bodyMedium(
                        color: AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
