import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class SummaryStat extends StatelessWidget {
  const SummaryStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption(color: AppColors.oroClaro.withAlpha(60)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.labelSemiBold(color: AppColors.oroClaro),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
