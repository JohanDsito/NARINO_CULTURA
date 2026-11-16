import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// Casilla de términos con área táctil completa.
class TermsCheck extends StatelessWidget {
  const TermsCheck({
    super.key,
    required this.accepted,
    required this.onChanged,
    this.enabled = true,
    this.showError = false,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final borderColor = showError
        ? nc.tomateA.fill
        : (accepted ? nc.azul.withValues(alpha: 0.6) : nc.border);
    return Semantics(
      checked: accepted,
      label: 'Acepto los Términos y Condiciones y la Política de Privacidad',
      onTap: enabled ? () => onChanged(!accepted) : null,
      excludeSemantics: true,
      child: NcPressable(
        onTap: enabled ? () => onChanged(!accepted) : null,
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          decoration: BoxDecoration(
            color: accepted ? nc.azulA.tint : nc.itemFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              IgnorePointer(
                child: Checkbox(value: accepted, onChanged: (_) {}),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.bodySmall(color: nc.textSecondary)
                        .copyWith(fontSize: 13),
                    children: [
                      const TextSpan(text: 'Acepto los '),
                      TextSpan(
                        text: 'Términos y Condiciones',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: nc.textPrimary),
                      ),
                      const TextSpan(text: ' y la '),
                      TextSpan(
                        text: 'Política de Privacidad',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: nc.textPrimary),
                      ),
                      const TextSpan(text: ' de Nariño Cultura.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
