import 'package:flutter/material.dart';

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
