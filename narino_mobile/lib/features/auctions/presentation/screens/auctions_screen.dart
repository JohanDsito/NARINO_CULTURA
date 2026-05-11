import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class AuctionsScreen extends ConsumerStatefulWidget {
  const AuctionsScreen({super.key});

  @override
  ConsumerState<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends ConsumerState<AuctionsScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncAuctions = ref.watch(auctionsProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final canCreate = role == 'artista' || role == 'admin';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Subastas',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/auctions/history'),
            icon:
                const Icon(Icons.history, color: AppColors.oroClaro, size: 18),
            label: Text(
              'Mi historial',
              style: AppTypography.labelSemiBold(color: AppColors.oroClaro),
            ),
          ),
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.oroClaro),
              tooltip: 'Abrir subasta',
              onPressed: () => context.go('/auctions/new'),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.tierraProfunda,
        onRefresh: () async => ref.read(auctionsProvider.notifier).loadActive(),
        child: asyncAuctions.when(
          loading: () => const _LoadingBody(),
          error: (e, _) => _ErrorBody(
            error: e.toString(),
            onRetry: () => ref.read(auctionsProvider.notifier).loadActive(),
          ),
          data: (list) => list.isEmpty
              ? const _EmptyBody()
              : _AuctionList(auctions: list, now: _now),
        ),
      ),
    );
  }
}

// ─── Estados de la lista ──────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 140),
        Center(
          child: CircularProgressIndicator(
              color: AppColors.tierraProfunda, strokeWidth: 2),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Text(
                  error,
                  style: AppTypography.bodySmall(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        const Center(
          child: Icon(Icons.gavel_outlined,
              size: 56, color: AppColors.borderLight),
        ),
        const SizedBox(height: 14),
        Text(
          'No hay subastas activas en este momento.',
          style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AuctionList extends StatelessWidget {
  const _AuctionList({required this.auctions, required this.now});

  final List<AuctionModel> auctions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: auctions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AuctionCard(auction: auctions[i], now: now),
    );
  }
}

// ─── Tarjeta de subasta ───────────────────────────────────────────────────────

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({required this.auction, required this.now});

  final AuctionModel auction;
  final DateTime now;

  Duration get _remaining {
    final diff = auction.fechaCierre.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatRemaining(Duration d) {
    if (d.inDays >= 1) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    final h = d.inHours.remainder(24).toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  ({Color bg, Color fg}) _badgeColors(String estado) => estado == 'activa'
      ? (bg: AppColors.indigoPalido, fg: AppColors.indigoNoche)
      : (bg: AppColors.bgSubtleLight, fg: AppColors.textSecondaryLight);

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final price =
        auction.totalPujas > 0 ? auction.precioActual : auction.precioBase;
    final colors = _badgeColors(auction.estado);
    final isUrgent = remaining.inMinutes < 60 && auction.estado == 'activa';

    return InkWell(
      onTap: () => context.go('/auctions/${auction.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.35)
                : AppColors.borderLight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _CardImage(imageUrl: auction.imagenUrl),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          auction.obraTitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSemiBold(
                              color: AppColors.textPrimaryLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          auction.estado.toUpperCase(),
                          style: AppTypography.caption(color: colors.fg),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    auction.artistaNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(
                        color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 10),

                  // Precio + tiempo
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${price.toStringAsFixed(0)}',
                          style: AppTypography.labelSemiBold(
                              color: AppColors.tierraProfunda),
                        ),
                      ),
                      Icon(
                        isUrgent
                            ? Icons.timer_outlined
                            : Icons.schedule_outlined,
                        size: 15,
                        color: isUrgent
                            ? AppColors.error
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRemaining(remaining),
                        style: AppTypography.caption(
                          color: isUrgent
                              ? AppColors.error
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.textMutedLight, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Imagen de la tarjeta ─────────────────────────────────────────────────────

class _CardImage extends StatelessWidget {
  const _CardImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const _FallbackImage();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 78,
      height: 78,
      fit: BoxFit.cover,
      placeholder: (_, __) => const _FallbackImage(loading: true),
      errorWidget: (_, __, ___) => const _FallbackImage(),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      color: AppColors.bgSubtleLight,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image_outlined,
                color: AppColors.textMutedLight, size: 28),
      ),
    );
  }
}
