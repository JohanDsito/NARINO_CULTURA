import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../providers/auctions_provider.dart';
import 'auction_history_screen/historial_subastas_lista.dart';

const _estados = <(String?, String)>[
  (null, 'Todas'),
  ('activa', 'Activas'),
  ('pendiente', 'En revisión'),
  ('cerrada', 'Finalizadas'),
  ('cancelada', 'Canceladas'),
];

/// Historial: "Mis pujas" (voy ganando o gané) y "Mis subastas" (las que abrí).
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
    final nc = context.nc;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi historial de subastas'),
          // Antes: etiqueta inactiva fija en blanco (invisible en claro).
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mis pujas'),
              Tab(text: 'Mis subastas'),
            ],
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                itemCount: _estados.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (valor, label) = _estados[i];
                  final sel = _estado == valor;
                  return ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _estado = valor),
                    selectedColor: nc.subastas.fill,
                    side: BorderSide(color: sel ? nc.subastas.fill : nc.border),
                    labelStyle: AppTypography.labelMedium(
                            color: sel ? nc.subastas.onFill : nc.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  HistorialSubastasLista(
                    params: AuctionHistoryParams(
                        mode: 'participante', estado: _estado),
                    vacioTitulo: 'Aún no has pujado',
                    vacioTexto: 'Aquí verás las subastas en las que '
                        'participes y cómo te va en cada una.',
                  ),
                  HistorialSubastasLista(
                    params:
                        AuctionHistoryParams(mode: 'artista', estado: _estado),
                    vacioTitulo: 'No has abierto subastas',
                    vacioTexto: 'Abre una con una de tus obras disponibles.',
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
