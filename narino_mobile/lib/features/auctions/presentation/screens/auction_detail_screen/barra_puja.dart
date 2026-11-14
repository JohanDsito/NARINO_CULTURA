import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../widgets/subasta_ui.dart';

/// Barra fija para pujar con montos sugeridos (+5 %, +10 %, +20 %).
class BarraPuja extends StatelessWidget {
  const BarraPuja({
    super.key,
    required this.controller,
    required this.precioActual,
    required this.loading,
    required this.onPujar,
  });

  final TextEditingController controller;
  final double precioActual;
  final bool loading;
  final VoidCallback onPujar;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    double redondear(double v) => (v / 1000).ceil() * 1000;
    final sugeridos = [1.05, 1.10, 1.20]
        .map((f) => redondear(precioActual * f))
        .toSet()
        .toList();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: nc.bgGlass,
            border: Border(top: BorderSide(color: nc.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final s in sugeridos) ...[
                    Expanded(
                      child: NcPressable(
                        onTap: () => controller.text = s.toStringAsFixed(0),
                        semanticLabel: 'Pujar ${formatCOP(s)}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: nc.subastas.tint,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color:
                                    nc.subastas.fill.withValues(alpha: 0.45)),
                          ),
                          child: Text(formatCOP(s),
                              style: AppTypography.labelMedium(
                                      color: nc.subastas.ink)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    if (s != sugeridos.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      enabled: !loading,
                      onSubmitted: (_) => onPujar(),
                      decoration: InputDecoration(
                        hintText: 'Más de ${formatCOP(precioActual)}',
                        prefixText: r'$ ',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide: BorderSide(color: nc.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(99),
                          borderSide:
                              BorderSide(color: nc.subastas.fill, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  NcPrimaryButton(
                    label: 'Pujar',
                    icon: Icons.gavel_rounded,
                    expand: false,
                    loading: loading,
                    onPressed: onPujar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
