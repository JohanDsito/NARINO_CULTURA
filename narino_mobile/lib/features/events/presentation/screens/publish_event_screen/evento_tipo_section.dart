import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../widgets/eventos_ui.dart';

/// "¿Qué tipo de evento es?": chips con el color de cada tipo.
class EventoTipoSection extends StatelessWidget {
  const EventoTipoSection({
    super.key,
    required this.tipo,
    required this.onChanged,
  });

  final String tipo;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcFormSection(
      title: '¿Qué tipo de evento es?',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in kTiposEvento)
              ChoiceChip(
                avatar: Icon(tipoIcon(t),
                    size: 16,
                    color: tipo == t
                        ? tipoAccent(nc, t).onFill
                        : tipoAccent(nc, t).ink),
                label: Text(tipoNombre(t)),
                selected: tipo == t,
                showCheckmark: false,
                onSelected: (_) => onChanged(t),
                selectedColor: tipoAccent(nc, t).fill,
                side: BorderSide(
                    color: tipo == t ? tipoAccent(nc, t).fill : nc.border),
                labelStyle: AppTypography.labelMedium(
                  color: tipo == t ? tipoAccent(nc, t).onFill : nc.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ],
    );
  }
}
