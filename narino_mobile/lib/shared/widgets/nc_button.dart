import 'package:flutter/material.dart';

class NcButton extends StatelessWidget {
  const NcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NcButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final NcButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 10),
        ],
        Text(label),
      ],
    );

    switch (variant) {
      case NcButtonVariant.primary:
        return ElevatedButton(onPressed: effectiveOnPressed, child: child);
      case NcButtonVariant.outlined:
        return OutlinedButton(onPressed: effectiveOnPressed, child: child);
      case NcButtonVariant.text:
        return TextButton(onPressed: effectiveOnPressed, child: child);
    }
  }
}

enum NcButtonVariant { primary, outlined, text }
