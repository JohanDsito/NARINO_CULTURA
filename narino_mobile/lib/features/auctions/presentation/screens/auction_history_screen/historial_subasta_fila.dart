import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../domain/auction_model.dart';
import '../../widgets/subasta_ui.dart';

class HistorialSubastaFila extends ConsumerWidget {
  const HistorialSubastaFila(
      {super.key, required this.auction, required this.participante});

  final AuctionModel auction;
  final bool participante;

  /// Cómo le fue al usuario en una subasta en la que pujó.
  (String, IconData, NcAccent)? _resultado(NcColors nc, String yo) {
    if (!participante || yo.isEmpty) return null;
    final a = auction;
    final cerrada = a.estado == 'cerrada';
    if (a.ganadorId == yo) {
      return ('Ganaste', Icons.emoji_events_rounded, nc.successA);
    }
    if (cerrada) return ('No ganaste', Icons.close_rounded, nc.tomateA);
    if (a.estado != 'activa') return null;
    return a.pujadorLiderId == yo
        ? ('Vas ganando', Icons.trending_up_rounded, nc.successA)
        : ('Te superaron', Icons.trending_down_rounded, nc.tomateA);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final fase = faseDe(auction);
    final yo = ref.watch(myProfileProvider).profile?.userId ?? '';
    final res = _resultado(nc, yo);
    return NcCard(
      padding: const EdgeInsets.all(12),
      gradientBorder: false,
      onTap: () => context.push('/auctions/${auction.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: SubastaImage(url: auction.imagenUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auction.obraTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    FaseBadge(fase: fase),
                    if (res != null)
                      NcStatusPill(label: res.$1, accent: res.$3, icon: res.$2),
                  ],
                ),
                const SizedBox(height: 6),
                Text(formatCOP(auction.precioActual),
                    style: AppTypography.labelSemiBold(color: nc.subastas.ink)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: nc.textMuted),
        ],
      ),
    );
  }
}
