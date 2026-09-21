import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight,
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: AppColors.indigoClaro, size: 32),
      ),
    );
  }
}
