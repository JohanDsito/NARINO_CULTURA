import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

class PuntosEscribiendo extends StatefulWidget {
  const PuntosEscribiendo({super.key});

  @override
  State<PuntosEscribiendo> createState() => _PuntosState();
}

class _PuntosState extends State<PuntosEscribiendo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final colores = [nc.tomateA.fill, nc.oroA.fill, nc.azulA.fill];
    return Semantics(
      label: 'El asistente está escribiendo',
      child: SizedBox(
        height: 20,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(
                        0,
                        -4 *
                            (1 -
                                ((_c.value * 3 - i) % 3 - 0.5)
                                    .abs()
                                    .clamp(0, 1)
                                    .toDouble())),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: colores[i], shape: BoxShape.circle),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
