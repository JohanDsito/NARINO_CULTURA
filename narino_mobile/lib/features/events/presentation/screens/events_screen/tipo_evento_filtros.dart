import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../widgets/eventos_ui.dart';

class TipoEventoFiltros extends StatelessWidget {
  const TipoEventoFiltros(
      {super.key, required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final opciones = <String?>[null, ...kTiposEvento];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = opciones[i];
          final sel = selected == t;
          final a = t == null ? nc.eventos : tipoAccent(nc, t);
          final fg = sel ? a.onFill : nc.textPrimary;
          return Semantics(
            selected: sel,
            button: true,
            label: t == null ? 'Todos' : tipoNombre(t),
            excludeSemantics: true,
            child: NcPressable(
              onTap: () => onSelect(sel && t != null ? null : t),
              pressedScale: 0.94,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? a.fill : nc.bgGlass,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: sel ? a.fill : nc.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t != null) ...[
                      Icon(tipoIcon(t), size: 16, color: sel ? fg : a.ink),
                      const SizedBox(width: 6),
                    ],
                    Text(t == null ? 'Todos' : tipoNombre(t),
                        style: AppTypography.labelMedium(color: fg)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
