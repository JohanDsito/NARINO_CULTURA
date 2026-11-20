import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/auction_model.dart';
import '../../widgets/subasta_ui.dart';

/// Cabecera con la imagen de la obra, la fase y la serpentina.
class SubastaAppBar extends StatelessWidget {
  const SubastaAppBar({super.key, required this.auction, required this.fase});

  final AuctionModel auction;
  final FaseSubasta fase;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: nc.bg,
      surfaceTintColor: Colors.transparent,
      shape: const Border(),
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      actions: [
        GlassCircleButton(
          icon: Icons.history_rounded,
          tooltip: 'Mi historial',
          onPressed: () => context.push('/auctions/history'),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: auction.obraId.isEmpty
                  ? null
                  : () => context.push('/artworks/${auction.obraId}'),
              child: SubastaImage(url: auction.imagenUrl),
            ),
            Positioned(
                left: 16,
                bottom: 44,
                child: FaseBadge(fase: fase, onImage: true)),
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nc.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const NcSerpentina(width: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
