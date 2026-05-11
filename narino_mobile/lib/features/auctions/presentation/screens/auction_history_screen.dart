import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/auction_model.dart';
import '../providers/auctions_provider.dart';

// ─── Constantes ───────────────────────────────────────────────────────────────

const _kEstados = <String?, String>{
  null: 'Todos',
  'activa': 'Activa',
  'cerrada': 'Cerrada',
  'cancelada': 'Cancelada',
};

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
            _EstadoFilter(
              value: _estado,
              onChanged: (v) => setState(() => _estado = v),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _HistoryList(
                    params: AuctionHistoryParams(
                        mode: 'participante', estado: _estado),
                  ),
                  _HistoryList(
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

// ─── Filtro de estado ─────────────────────────────────────────────────────────

class _EstadoFilter extends StatelessWidget {
  const _EstadoFilter({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list_outlined,
              size: 18, color: AppColors.textMutedLight),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kEstados.entries.map((entry) {
                  final isSelected = value == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        entry.value,
                        style: AppTypography.caption(
                          color: isSelected
                              ? AppColors.tierraProfunda
                              : AppColors.textMutedLight,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => onChanged(entry.key),
                      backgroundColor: AppColors.bgSubtleLight,
                      selectedColor: AppColors.tierraPalida,
                      checkmarkColor: Colors.transparent,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.tierraProfunda
                            : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista del historial ──────────────────────────────────────────────────────

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.params});

  final AuctionHistoryParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(auctionHistoryProvider(params));

    return asyncList.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppColors.tierraProfunda, strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 44, color: AppColors.textMutedLight),
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
          return _EmptyHistory(params: params);
        }

        return RefreshIndicator(
          color: AppColors.tierraProfunda,
          onRefresh: () async {
            ref.invalidate(auctionHistoryProvider(params));
            await ref.read(auctionHistoryProvider(params).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AuctionTile(auction: list[i]),
          ),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.params});

  final AuctionHistoryParams params;

  @override
  Widget build(BuildContext context) {
    final isPujas = params.mode == 'participante';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gavel_outlined,
                size: 52, color: AppColors.borderLight),
            const SizedBox(height: 14),
            Text(
              isPujas
                  ? 'Aún no has participado en subastas.'
                  : 'Aún no has creado subastas.',
              style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile de subasta ──────────────────────────────────────────────────────────

class _AuctionTile extends StatelessWidget {
  const _AuctionTile({required this.auction});

  final AuctionModel auction;

  Color _estadoBg(String estado) => switch (estado) {
        'activa' => AppColors.indigoPalido,
        'cerrada' => AppColors.tierraPalida,
        _ => AppColors.bgSubtleLight,
      };

  Color _estadoFg(String estado) => switch (estado) {
        'activa' => AppColors.indigoNoche,
        'cerrada' => AppColors.tierraProfunda,
        _ => AppColors.textMutedLight,
      };

  String _estadoLabel(String estado) => switch (estado) {
        'activa' => 'Activa',
        'cerrada' => 'Cerrada',
        'cancelada' => 'Cancelada',
        _ => estado,
      };

  @override
  Widget build(BuildContext context) {
    final estado = auction.estado;

    return InkWell(
      onTap: () => context.go('/auctions/${auction.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _TileImage(imageUrl: auction.imagenUrl),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.obraTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(
                        color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _estadoBg(estado),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          _estadoLabel(estado),
                          style:
                              AppTypography.caption(color: _estadoFg(estado)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${auction.totalPujas} pujas',
                        style: AppTypography.caption(
                            color: AppColors.textMutedLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${auction.precioActual.toStringAsFixed(0)}',
                    style:
                        AppTypography.labelSemiBold(color: AppColors.oroAndino),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right,
                color: AppColors.textMutedLight, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return _PlaceholderBox();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      placeholder: (_, __) => _PlaceholderBox(),
      errorWidget: (_, __, ___) => _PlaceholderBox(),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.bgSubtleLight,
      child: const Icon(Icons.image_outlined,
          color: AppColors.textMutedLight, size: 24),
    );
  }
}
