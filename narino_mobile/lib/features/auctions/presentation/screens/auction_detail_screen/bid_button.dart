import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class BidButton extends StatelessWidget {
  const BidButton({super.key, required this.isBidding, required this.onPressed});

  final bool isBidding;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isBidding ? null : onPressed,
        icon: isBidding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.gavel_outlined),
        label: Text(
          isBidding ? 'Enviando...' : 'Pujar',
          style: AppTypography.buttonText(color: Colors.white),
        ),
      ),
    );
  }
}
