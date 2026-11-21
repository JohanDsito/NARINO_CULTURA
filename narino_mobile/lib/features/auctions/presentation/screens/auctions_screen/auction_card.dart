import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/auction_model.dart';
import '../../widgets/subasta_ui.dart';
import 'tiempo_pill.dart';

class AuctionCard extends StatelessWidget {
  const AuctionCard({super.key, required this.auction, required this.myId});

  final AuctionModel auction;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final fase = faseDe(auction);
    final vasGanando = myId != null &&
        auction.pujadorLiderId == myId &&
        fase == FaseSubasta.enVivo;
    final hayPujas = auction.pujadorLiderId != null ||
        auction.precioActual > auction.precioBase;

    return NcCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/auctions/${auction.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SubastaImage(url: auction.imagenUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                Positioned(
                    left: 12,
                    top: 12,
                    child: FaseBadge(fase: fase, onImage: true)),
                if (vasGanando)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: nc.successA.fill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('VAS GANANDO',
                          style:
                              AppTypography.caption(color: nc.successA.onFill)
                                  .copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: TiempoPill(auction: auction, fase: fase),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auction.obraTitulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displaySemiBold(
                                  color: nc.textPrimary)
                              .copyWith(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(auction.artistaNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.bodySmall(color: nc.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(hayPujas ? 'Puja actual' : 'Precio base',
                        style:
                            AppTypography.bodySmall(color: nc.textSecondary)),
                    Text(formatCOP(auction.precioActual),
                        style: AppTypography.price(color: nc.subastas.ink)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
