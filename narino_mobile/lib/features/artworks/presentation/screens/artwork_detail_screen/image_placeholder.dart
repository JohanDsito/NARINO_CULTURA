import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final bgSubtle = nc.itemFill;
    return Container(
      color: bgSubtle,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
        ),
      ),
    );
  }
}
