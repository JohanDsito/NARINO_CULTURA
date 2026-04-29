import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';

class AuctionHistoryScreen extends ConsumerStatefulWidget {
  const AuctionHistoryScreen({super.key});

  @override
  ConsumerState<AuctionHistoryScreen> createState() => _AuctionHistoryScreenState();
}

class _AuctionHistoryScreenState extends ConsumerState<AuctionHistoryScreen> {
  String? _estado;

  String _labelEstado(String? v) {
    switch (v) {
      case 'activa':
        return 'Activa';
      case 'cerrada':
        return 'Cerrada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Todos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _estado,
                    isExpanded: true,
                    dropdownColor: AppColors.bgCardLight,
                    iconEnabledColor: AppColors.textMutedLight,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'activa', child: Text('Activa')),
                      DropdownMenuItem(value: 'cerrada', child: Text('Cerrada')),
                      DropdownMenuItem(
                        value: 'cancelada',
                        child: Text('Cancelada'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _estado = v),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filtro: ${_labelEstado(_estado)}',
                  style: AppTypography.caption(color: AppColors.textMutedLight),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _HistoryList(
                    params: AuctionHistoryParams(mode: 'participante', estado: _estado),
                  ),
                  _HistoryList(
                    params: AuctionHistoryParams(mode: 'artista', estado: _estado),
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

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.params});

  final AuctionHistoryParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(auctionHistoryProvider(params));

    return asyncList.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.tierraProfunda),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            e.toString(),
            style: AppTypography.bodySmall(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No hay subastas para mostrar.',
              style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.tierraProfunda,
          onRefresh: () async {
            ref.invalidate(auctionHistoryProvider(params));
            await ref.read(auctionHistoryProvider(params).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AuctionTile(auction: list[i]),
          ),
        );
      },
    );
  }
}

class _AuctionTile extends StatelessWidget {
  const _AuctionTile({required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    final estado = auction.estado;
    final estadoLabel = switch (estado) {
      'activa' => 'Activa',
      'cerrada' => 'Cerrada',
      'cancelada' => 'Cancelada',
      _ => estado,
    };

    return InkWell(
      onTap: () => context.go('/auctions/${auction.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: auction.imagenUrl != null
                ? Image.network(
                    auction.imagenUrl!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 54,
                      height: 54,
                      color: AppColors.bgLight,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  )
                : Container(
                    width: 54,
                    height: 54,
                    color: AppColors.bgLight,
                    child: const Icon(Icons.image_outlined),
                  ),
          ),
          title: Text(
            auction.obraTitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSemiBold(color: AppColors.textPrimaryLight),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$estadoLabel · ${auction.totalPujas} pujas · \$${auction.precioActual.toStringAsFixed(0)}',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

