import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      color: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
      child: const Icon(
        Icons.music_note_outlined,
        color: AppColors.indigoClaro,
        size: 28,
      ),
    );
  }
}
