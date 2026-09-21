import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.gavel_outlined),
        label: Text(
          isSubmitting ? 'Abriendo...' : 'Abrir subasta',
          style: AppTypography.buttonText(color: Colors.white),
        ),
      ),
    );
  }
}
