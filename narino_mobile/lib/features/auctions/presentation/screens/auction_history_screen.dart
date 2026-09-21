import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auctions_provider.dart';
import 'auction_history_screen/estado_filter.dart';
import 'auction_history_screen/history_list.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class AuctionHistoryScreen extends ConsumerStatefulWidget {
  const AuctionHistoryScreen({super.key});

  @override
  ConsumerState<AuctionHistoryScreen> createState() =>
      _AuctionHistoryScreenState();
}

class _AuctionHistoryScreenState extends ConsumerState<AuctionHistoryScreen> {
  String? _estado;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.obsidiana,
          foregroundColor: AppColors.oroClaro,
          title: Text(
            'Historial de subastas',
            style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.oroClaro,
            labelColor: AppColors.oroClaro,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Mis pujas'),
              Tab(text: 'Mis subastas'),
            ],
          ),
        ),
        body: Column(
          children: [
            EstadoFilter(
              value: _estado,
              onChanged: (v) => setState(() => _estado = v),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  HistoryList(
                    params: AuctionHistoryParams(
                        mode: 'participante', estado: _estado),
                  ),
                  HistoryList(
                    params:
                        AuctionHistoryParams(mode: 'artista', estado: _estado),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
