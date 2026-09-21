import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class FlyerPlaceholder extends StatelessWidget {
  const FlyerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.obsidiana,
      child: const Center(
        child: Icon(Icons.event_outlined, color: AppColors.oroClaro, size: 64),
      ),
    );
  }
}
