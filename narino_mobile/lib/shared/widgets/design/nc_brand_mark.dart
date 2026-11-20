import 'package:flutter/material.dart';
import '../../../core/theme/nc_theme.dart';

/// Logo: cuadro de 34 px, radio 10, "N" sobre degradado naranja → magenta.
class NcBrandMark extends StatelessWidget {
  const NcBrandMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: context.nc.brandGradient,
        borderRadius: BorderRadius.circular(size * 10 / 34),
      ),
      child: Text(
        'N',
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
          height: 1,
        ),
      ),
    );
  }
}
