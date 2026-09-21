import 'package:flutter/material.dart';

// ─── Widgets compartidos ──────────────────────────────────────────────────────

class ToggleVisibility extends StatelessWidget {
  const ToggleVisibility({
    super.key,
    required this.obscure,
    required this.disabled,
    required this.onToggle,
  });

  final bool obscure;
  final bool disabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: disabled ? null : onToggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }
}
