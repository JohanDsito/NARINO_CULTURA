import 'package:flutter/material.dart';
import '../../../core/theme/nc_theme.dart';

/// Franja "serpentina" con el degradado carnaval completo.
class NcSerpentina extends StatelessWidget {
  const NcSerpentina({super.key, this.width = 64, this.height = 4});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: context.nc.carnavalGradient,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
