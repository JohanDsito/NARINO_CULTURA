import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.modoEdicion,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final bool modoEdicion;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: cs.onPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                modoEdicion ? 'Guardar cambios' : 'Publicar obra',
                style: AppTypography.buttonText(color: cs.onPrimary),
              ),
      ),
    );
  }
}
