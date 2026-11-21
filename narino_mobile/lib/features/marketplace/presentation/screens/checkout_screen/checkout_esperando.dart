import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

class CheckoutEsperando extends StatelessWidget {
  const CheckoutEsperando({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: nc.azulA.tint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: nc.azul.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child:
                  CircularProgressIndicator(strokeWidth: 2.4, color: nc.azul),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Esperando la confirmación del pago…',
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)
                          .copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                      'Termina el pago en Wompi. Esta pantalla se actualiza '
                      'sola.',
                      style: AppTypography.bodySmall(color: nc.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
