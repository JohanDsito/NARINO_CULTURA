import 'package:flutter/material.dart';

import '../../../../../core/theme/nc_theme.dart';

class ImageEmpty extends StatelessWidget {
  const ImageEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final bgSubtle = nc.itemFill;
    final iconColor = nc.textMuted;
    return Container(
      color: bgSubtle,
      child: Icon(Icons.palette_outlined, size: 60, color: iconColor),
    );
  }
}
