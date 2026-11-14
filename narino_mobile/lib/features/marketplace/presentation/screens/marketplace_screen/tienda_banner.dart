import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class TiendaBanner extends StatelessWidget {
  const TiendaBanner({super.key, required this.esArtista});

  final bool esArtista;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final atajos = <(IconData, String, String, NcAccent)>[
      (
        Icons.receipt_long_outlined,
        'Mis compras',
        '/marketplace/purchases',
        nc.tienda
      ),
      (
        Icons.favorite_border_rounded,
        'Favoritos',
        '/marketplace/favorites',
        nc.magentaA
      ),
      if (esArtista)
        (
          Icons.trending_up_rounded,
          'Mis ventas',
          '/marketplace/sales',
          nc.oroA
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NcCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ARTE ORIGINAL DE NARIÑO',
                style: AppTypography.kicker(color: nc.oroA.ink)),
            const SizedBox(height: 8),
            Text('Compra directo al creador',
                style: AppTypography.displayBold(color: nc.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'Cada compra apoya a artesanos, pintores y fotógrafos del '
              'departamento. Pago seguro con Wompi.',
              style: AppTypography.bodyMedium(color: nc.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in atajos)
                  NcPressable(
                    onTap: () => context.push(a.$3),
                    semanticLabel: a.$2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: a.$4.tint,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: a.$4.fill.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.$1, size: 16, color: a.$4.ink),
                          const SizedBox(width: 6),
                          Text(a.$2,
                              style: AppTypography.labelMedium(color: a.$4.ink)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
