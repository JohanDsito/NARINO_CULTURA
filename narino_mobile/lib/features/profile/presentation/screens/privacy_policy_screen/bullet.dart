import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class Bullet extends StatelessWidget {
  const Bullet(this.text, {super.key, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTypography.bodySmall(color: color))),
          ],
        ),
      );
}
