import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';

/// Campo de contraseña con botón mostrar/ocultar.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          onPressed: widget.enabled
              ? () => setState(() => _obscure = !_obscure)
              : null,
          icon: Icon(_obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
        ),
      ),
    );
  }
}

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

/// Opción de rol en el registro (tarjeta seleccionable con su color).
class RoleOption extends StatelessWidget {
  const RoleOption({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final NcAccent accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(accent.tint, nc.bgCard)
                : nc.itemFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent.fill : nc.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow:
                selected && nc.isDark ? nc.tintedShadow(accent.fill) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent.fill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          size: 15, color: accent.onFill),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTypography.labelSemiBold(
                    color: selected ? accent.ink : nc.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodySmall(
                    color: selected
                        ? nc.textPrimary.withValues(alpha: 0.85)
                        : nc.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
