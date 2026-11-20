import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// "Precio": a la venta (con precio) o solo exhibición.
class ObraPrecioSection extends StatelessWidget {
  const ObraPrecioSection({
    super.key,
    required this.aLaVenta,
    required this.precio,
    required this.editable,
    required this.onModo,
  });

  final bool aLaVenta;
  final TextEditingController precio;
  final bool editable;
  final ValueChanged<bool> onModo;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcFormSection(
      title: 'Precio',
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('A la venta'),
              icon: Icon(Icons.sell_outlined),
            ),
            ButtonSegment(
              value: false,
              label: Text('Exhibición'),
              icon: Icon(Icons.visibility_outlined),
            ),
          ],
          selected: {aLaVenta},
          showSelectedIcon: false,
          onSelectionChanged: editable ? (s) => onModo(s.first) : null,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: nc.tienda.fill,
            selectedForegroundColor: nc.tienda.onFill,
            side: BorderSide(color: nc.border),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              aLaVenta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: TextFormField(
            controller: precio,
            enabled: editable,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Precio en pesos',
              prefixText: r'$ ',
              suffixText: 'COP',
            ),
            validator: (v) {
              if (!aLaVenta) return null;
              final n = double.tryParse(v?.trim() ?? '');
              if (n == null || n <= 0) return 'Escribe un precio mayor que 0';
              return null;
            },
          ),
          secondChild: Text(
            'La obra aparecerá en el catálogo sin opción de compra. Podrás '
            'ponerla a la venta después.',
            style: AppTypography.bodySmall(color: nc.textSecondary),
          ),
        ),
      ],
    );
  }
}
