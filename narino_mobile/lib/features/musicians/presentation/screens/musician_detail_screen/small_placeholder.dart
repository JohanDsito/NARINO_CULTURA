import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class SmallPlaceholder extends StatelessWidget {
  const SmallPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.indigoNoche,
      child: const Icon(Icons.music_note_outlined,
          color: AppColors.indigoClaro, size: 28),
    );
  }
}
