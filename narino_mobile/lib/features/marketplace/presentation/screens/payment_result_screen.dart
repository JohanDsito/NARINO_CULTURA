import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../widgets/tienda_ui.dart';

/// Resultado del pago en Wompi: celebración si salió bien, salida clara si no.
class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.orderId,
    required this.success,
  });

  final String orderId;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final accent = success ? nc.successA : nc.tomateA;

    return Scaffold(
      backgroundColor: nc.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: CarnavalBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: NcCard(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                    child: Column(
                      children: [
                        NcAccentIcon(
                          icon: success
                              ? Icons.celebration_outlined
                              : Icons.error_outline_rounded,
                          accent: accent,
                          size: 88,
                          glow: true,
                        ),
                        const SizedBox(height: 18),
                        if (success) ...[
                          const NcSerpentina(width: 80),
                          const SizedBox(height: 18),
                        ],
                        Semantics(
                          header: true,
                          liveRegion: true,
                          child: Text(
                            success ? '¡Pago confirmado!' : 'El pago no se completó',
                            textAlign: TextAlign.center,
                            style: AppTypography.displayBold(
                                color: nc.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          success
                              ? 'Tu orden ${codigoOrden(orderId)} quedó pagada. '
                                  'Te enviamos el comprobante al correo y el '
                                  'artista ya fue notificado.'
                              : 'No pudimos confirmar el pago de la orden '
                                  '${codigoOrden(orderId)}. No se hizo ningún '
                                  'cobro; puedes intentarlo de nuevo.',
                          textAlign: TextAlign.center,
                          style:
                              AppTypography.bodyMedium(color: nc.textSecondary),
                        ),
                        const SizedBox(height: 26),
                        if (success) ...[
                          NcPrimaryButton(
                            label: 'Ver mis compras',
                            icon: Icons.receipt_long_outlined,
                            onPressed: () =>
                                context.go('/marketplace/purchases'),
                          ),
                          const SizedBox(height: 10),
                          NcSecondaryButton(
                            label: 'Seguir explorando',
                            onPressed: () => context.go('/marketplace'),
                          ),
                        ] else ...[
                          NcPrimaryButton(
                            label: 'Intentar de nuevo',
                            icon: Icons.refresh_rounded,
                            // Antes volvía al carrito, que ya está vacío.
                            onPressed: () => context.go(
                                '/marketplace/checkout?orderId=$orderId'),
                          ),
                          const SizedBox(height: 10),
                          NcSecondaryButton(
                            label: 'Volver a la tienda',
                            onPressed: () => context.go('/marketplace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
