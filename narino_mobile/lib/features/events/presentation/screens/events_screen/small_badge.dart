import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';

class SmallBadge extends StatelessWidget {
  const SmallBadge({super.key, required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: AppTypography.caption(color: fg).copyWith(fontSize: 10),
      ),
    );
  }
}
