import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class ZoomButton extends StatelessWidget {
  const ZoomButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.zoom_out_map, size: 15, color: Colors.white),
              const SizedBox(width: 5),
              Text('Ver', style: AppTypography.caption(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
