import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Medidor de fuerza de la contraseña con las reglas del backend:
/// 8+ caracteres, una mayúscula y un número.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final rules = <(String, bool)>[
      ('8+ caracteres', password.length >= 8),
      ('Una mayúscula', RegExp('[A-Z]').hasMatch(password)),
      ('Un número', RegExp(r'\d').hasMatch(password)),
    ];
    final met = rules.where((r) => r.$2).length;
    final accent = switch (met) {
      0 || 1 => nc.tomateA,
      2 => nc.oroA,
      _ => nc.successA,
    };
    final label = switch (met) {
      0 => 'Escribe una contraseña',
      1 => 'Débil',
      2 => 'Casi lista',
      _ => 'Segura',
    };

    return Semantics(
      label: 'Fuerza de la contraseña: $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < met ? accent.fill : nc.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final r in rules)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      r.$2
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: r.$2 ? nc.successA.ink : nc.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.$1,
                      style: AppTypography.bodySmall(
                          color: r.$2 ? nc.textPrimary : nc.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
