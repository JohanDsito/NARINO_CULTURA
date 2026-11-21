import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Círculo con la serpentina y el ícono del asistente.
class AvatarAsistente extends StatelessWidget {
  const AvatarAsistente({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [
          ...nc.carnavalGradient.colors,
          nc.carnavalGradient.colors.first,
        ]),
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: Container(
        decoration: BoxDecoration(color: nc.bgCard, shape: BoxShape.circle),
        child:
            Icon(Icons.auto_awesome_rounded, size: size * 0.5, color: nc.azul),
      ),
    );
  }
}
