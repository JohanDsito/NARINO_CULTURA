import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auctions_provider.dart';
import 'auctions_screen/auction_list.dart';
import 'auctions_screen/empty_body.dart';
import 'auctions_screen/error_body.dart';
import 'auctions_screen/loading_body.dart';

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
    final cs = Theme.of(context).colorScheme;

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
            onPressed: () => context.push('/auctions/history'),
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
              onPressed: () => context.push('/auctions/new'),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async => ref.read(auctionsProvider.notifier).loadActive(),
        child: asyncAuctions.when(
          loading: () => const LoadingBody(),
          error: (e, _) => ErrorBody(
            error: e.toString(),
            onRetry: () => ref.read(auctionsProvider.notifier).loadActive(),
          ),
          data: (list) => list.isEmpty
              ? const EmptyBody()
              : AuctionList(auctions: list, now: _now),
        ),
      ),
    );
  }
}
