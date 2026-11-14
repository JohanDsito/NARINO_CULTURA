import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import 'policy_highlight.dart';

/// Encabezado de la política y el resumen "Lo esencial".
class PolicyIntro extends StatelessWidget {
  const PolicyIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            NcAccentIcon(
                icon: Icons.shield_outlined,
                accent: nc.successA,
                size: 60,
                glow: true),
            const SizedBox(height: 14),
            Text('Política de Privacidad',
                textAlign: TextAlign.center,
                style: AppTypography.displayBold(color: nc.textPrimary)
                    .copyWith(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
                'Nariño Cultura · Versión 1.1 · 2026\n'
                'Universidad Cooperativa de Colombia',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(color: nc.textMuted)),
            const SizedBox(height: 12),
            const NcSerpentina(width: 56),
          ],
        ),
        const SizedBox(height: 20),

        // Lo esencial: frases tomadas de la política.
        NcCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lo esencial',
                  style: AppTypography.displaySemiBold(color: nc.textPrimary)
                      .copyWith(fontSize: 17)),
              const SizedBox(height: 8),
              PolicyHighlight(
                  icon: Icons.block_rounded,
                  accent: nc.successA,
                  text: 'La Plataforma NO vende, alquila ni comparte datos '
                      'personales con fines comerciales.'),
              PolicyHighlight(
                  icon: Icons.credit_card_off_outlined,
                  accent: nc.tienda,
                  text: 'Los pagos los procesa Wompi. La Plataforma NO '
                      'almacena datos de tarjetas.'),
              PolicyHighlight(
                  icon: Icons.verified_user_outlined,
                  accent: nc.azulA,
                  text: 'El ejercicio de tus derechos no tiene ningún costo.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
