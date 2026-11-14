import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Estrellas de 0 a 5 (con media estrella).
class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.valor, this.size = 16});

  final double valor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      label: '${valor.toStringAsFixed(1)} de 5 estrellas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              valor >= i
                  ? Icons.star_rounded
                  : (valor >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
              size: size,
              color: nc.oro,
            ),
        ],
      ),
    );
  }
}
