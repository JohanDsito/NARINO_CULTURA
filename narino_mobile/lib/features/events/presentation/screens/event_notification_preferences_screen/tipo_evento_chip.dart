import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../widgets/eventos_ui.dart';

class TipoEventoChip extends StatelessWidget {
  const TipoEventoChip({
    super.key,
    required this.tipo,
    required this.activo,
    required this.onTap,
  });

  final String tipo;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = tipoAccent(nc, tipo);
    return Semantics(
      toggled: activo,
      button: true,
      label: tipoNombre(tipo),
      onTap: onTap,
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? a.fill : nc.itemFill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: activo ? a.fill : nc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activo ? Icons.check_rounded : tipoIcon(tipo),
                  size: 16, color: activo ? a.onFill : a.ink),
              const SizedBox(width: 6),
              Text(tipoNombre(tipo),
                  style: AppTypography.labelMedium(
                          color: activo ? a.onFill : nc.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
