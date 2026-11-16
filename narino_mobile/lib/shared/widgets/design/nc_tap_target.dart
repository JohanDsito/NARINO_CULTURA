import 'package:flutter/widgets.dart';

/// Área táctil mínima que pide Android (48 × 48 dp). MO-ACC-04.
const double kNcMinTapTarget = 48;

/// Da a [child] un área táctil de al menos 48 × 48 sin cambiar cómo se ve:
/// el dibujo (40–44 px en botones de ícono y corazones) queda centrado.
class NcTapTarget extends StatelessWidget {
  const NcTapTarget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kNcMinTapTarget,
          minHeight: kNcMinTapTarget,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      );
}
