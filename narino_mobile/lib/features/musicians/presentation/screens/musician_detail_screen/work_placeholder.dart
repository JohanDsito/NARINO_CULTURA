import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class WorkPlaceholder extends StatelessWidget {
  const WorkPlaceholder({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
      child: const Icon(Icons.music_note_outlined,
          color: AppColors.indigoClaro, size: 22),
    );
  }
}
