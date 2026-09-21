import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class SubTitle extends StatelessWidget {
  const SubTitle(this.text, {super.key, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppTypography.labelSemiBold(color: color).copyWith(fontSize: 12)),
      );
}
