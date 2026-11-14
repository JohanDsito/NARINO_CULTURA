import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/auction_model.dart';

/// Tarjeta para quien ganó: invita a pagar la orden de la subasta.
class GanasteSubastaCard extends StatelessWidget {
  const GanasteSubastaCard({super.key, required this.auction});

  final AuctionModel auction;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = auction;
    return NcCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          NcAccentIcon(
              icon: Icons.emoji_events_outlined,
              accent: nc.subastas,
              size: 60,
              glow: true),
          const SizedBox(height: 12),
          Text('¡Ganaste la subasta!',
              style: AppTypography.displaySemiBold(color: nc.textPrimary)),
          const SizedBox(height: 4),
          Text('Completa el pago para recibir tu obra.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(color: nc.textSecondary)),
          const SizedBox(height: 16),
          NcPrimaryButton(
            label: 'Pagar ${formatCOP(a.precioActual)}',
            icon: Icons.credit_card_rounded,
            onPressed: a.orderId == null
                ? () => ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(
                      content: Text('Estamos generando tu orden de pago. '
                          'Desliza hacia abajo en unos segundos.')))
                : () =>
                    context.push('/marketplace/checkout?orderId=${a.orderId}'),
          ),
        ],
      ),
    );
  }
}
