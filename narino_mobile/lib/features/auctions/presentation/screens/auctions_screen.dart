import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';

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
      if (!mounted) return;
      setState(() => _now = DateTime.now());
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
    final profileState = ref.watch(myProfileProvider);
    final canCreateAuction = profileState.profile != null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
          if (canCreateAuction)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.oroClaro),
              onPressed: () => context.go('/auctions/new'),
            ),
        ],
      ),
      body: asyncAuctions.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.tierraProfunda),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    e.toString(),
                    style: AppTypography.bodySmall(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(auctionsProvider.notifier).loadActive(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No hay subastas activas en este momento.',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.tierraProfunda,
            onRefresh: () async {
              await ref.read(auctionsProvider.notifier).loadActive();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AuctionCard(auction: list[i], now: _now),
            ),
          );
        },
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({required this.auction, required this.now});

  final AuctionModel auction;
  final DateTime now;

  Duration get _remaining {
    final diff = auction.fechaCierre.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatRemaining(Duration d) {
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    return '${days}d ${hours}h ${minutes}m';
  }

  ({Color bg, Color fg}) _badgeColors(String estado) {
    if (estado == 'activa') {
      return (bg: AppColors.indigoPalido, fg: AppColors.indigoNoche);
    }
    return (bg: AppColors.borderLight, fg: AppColors.textSecondaryLight);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final price =
        auction.totalPujas > 0 ? auction.precioActual : auction.precioBase;
    final colors = _badgeColors(auction.estado);
    final isLastHour = remaining.inMinutes < 60 && auction.estado == 'activa';

    return InkWell(
      onTap: () => context.go('/auctions/${auction.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: auction.imagenUrl != null
                    ? Image.network(
                        auction.imagenUrl!,
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 78,
                          height: 78,
                          color: AppColors.bgLight,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      )
                    : Container(
                        width: 78,
                        height: 78,
                        color: AppColors.bgLight,
                        child: const Icon(Icons.image_outlined),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            auction.obraTitulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.displaySemiBold(
                              color: AppColors.textPrimaryLight,
                            ).copyWith(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            auction.estado.toUpperCase(),
                            style: AppTypography.caption(color: colors.fg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auction.artistaNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(
                          color: AppColors.textMutedLight),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${price.toStringAsFixed(0)}',
                            style: AppTypography.price(
                              color: AppColors.tierraProfunda,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 16,
                              color: isLastHour
                                  ? AppColors.error
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatRemaining(remaining),
                              style: AppTypography.labelSemiBold(
                                color: isLastHour
                                    ? AppColors.error
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child:
                    Icon(Icons.chevron_right, color: AppColors.textMutedLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
