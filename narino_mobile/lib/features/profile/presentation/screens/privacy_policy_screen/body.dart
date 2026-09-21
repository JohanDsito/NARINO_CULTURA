import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

class PolicyBody extends StatelessWidget {
  const PolicyBody(this.text, {super.key, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.bodySmall(color: color));
}
