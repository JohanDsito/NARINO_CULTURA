import 'package:flutter/material.dart';
import '../../../core/theme/nc_theme.dart';
import 'nc_brand_mark.dart';

/// Marca completa: logo + "Nariño Cultura" (+ subtítulo opcional).
class NcBrand extends StatelessWidget {
  const NcBrand({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Semantics(
      label: 'Nariño Cultura',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NcBrandMark(),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nariño Cultura',
                style: TextStyle(
                  fontFamily: family,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.48,
                  height: 1.15,
                  color: nc.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: family,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: nc.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
