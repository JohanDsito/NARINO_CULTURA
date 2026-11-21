import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../domain/auction_bid_model.dart';
import '../../widgets/subasta_ui.dart';

class PujasEnVivo extends StatelessWidget {
  const PujasEnVivo({
    super.key,
    required this.pujas,
    required this.resaltar,
    required this.enVivo,
  });

  final List<AuctionBidModel> pujas;
  final bool resaltar;
  final bool enVivo;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final palette = [nc.tomateA, nc.naranjaA, nc.oroA, nc.magentaA, nc.azulA];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Pujas en vivo',
                style: AppTypography.displaySemiBold(color: nc.textPrimary)),
            if (enVivo) ...[
              const SizedBox(width: 8),
              LiveDot(color: nc.enVivo.ink),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Aquí aparecen las pujas que llegan mientras tienes la subasta '
          'abierta.',
          style: AppTypography.bodySmall(color: nc.textSecondary),
        ),
        const SizedBox(height: 12),
        if (pujas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: nc.itemFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: nc.border),
            ),
            child: Text(
              enVivo
                  ? 'Todavía no llegan pujas nuevas. ¡Puedes ser la primera '
                      'persona en pujar!'
                  : 'No hay pujas para mostrar.',
              style: AppTypography.bodyMedium(color: nc.textSecondary),
            ),
          )
        else
          for (var i = 0; i < pujas.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: i == 0 && resaltar ? nc.subastas.tint : nc.itemFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: i == 0 && resaltar
                        ? nc.subastas.fill.withValues(alpha: 0.5)
                        : nc.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: palette[i % palette.length].fill,
                    child: Text(
                      pujas[i].bidderName.isNotEmpty
                          ? pujas[i].bidderName.characters.first.toUpperCase()
                          : '?',
                      style: AppTypography.labelSemiBold(
                              color: palette[i % palette.length].onFill)
                          .copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(pujas[i].esMia ? 'Tú' : pujas[i].bidderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTypography.labelSemiBold(color: nc.textPrimary)
                                .copyWith(fontSize: 14)),
                  ),
                  Text(formatCOP(pujas[i].amount),
                      style: AppTypography.labelSemiBold(
                          color: i == 0 ? nc.subastas.ink : nc.textSecondary)),
                ],
              ),
            ),
      ],
    );
  }
}
