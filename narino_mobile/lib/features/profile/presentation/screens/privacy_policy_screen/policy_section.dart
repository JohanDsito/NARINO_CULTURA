import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Sección plegable de la política.
class PolicySection extends StatelessWidget {
  const PolicySection({
    super.key,
    required this.numero,
    required this.titulo,
    required this.children,
    this.accent,
    this.abierta = false,
  });

  final int numero;
  final String titulo;
  final List<Widget> children;
  final NcAccent? accent;
  final bool abierta;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: a == null ? nc.bgCard : Color.alphaBlend(a.tint, nc.bgCard),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: a == null ? nc.border : a.fill.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        // Material propio: sin él, el fondo de la caja tapaba el efecto de
        // toque del ExpansionTile.
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: abierta,
              tilePadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: a?.ink ?? nc.textSecondary,
              collapsedIconColor: nc.textMuted,
              leading: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: a?.fill ?? nc.itemFill,
                  shape: BoxShape.circle,
                ),
                child: Text('$numero',
                    style: AppTypography.labelMedium(
                            color: a?.onFill ?? nc.textSecondary)
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
              title: Text(titulo,
                  style: AppTypography.labelSemiBold(
                      color: a?.ink ?? nc.textPrimary)),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
