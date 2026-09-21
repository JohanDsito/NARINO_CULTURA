import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../providers/auctions_provider.dart';
import 'auction_tile.dart';
import 'empty_history.dart';

// ─── Lista del historial ──────────────────────────────────────────────────────

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key, required this.params});

  final AuctionHistoryParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(auctionHistoryProvider(params));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return asyncList.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 44, color: textMuted),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                style: AppTypography.bodySmall(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(auctionHistoryProvider(params)),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyHistory(params: params);
        }

        return RefreshIndicator(
          color: cs.primary,
          onRefresh: () async {
            ref.invalidate(auctionHistoryProvider(params));
            await ref.read(auctionHistoryProvider(params).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => AuctionTile(auction: list[i]),
          ),
        );
      },
    );
  }
}
