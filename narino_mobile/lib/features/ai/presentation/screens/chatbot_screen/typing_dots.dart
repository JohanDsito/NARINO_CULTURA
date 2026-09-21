import 'package:flutter/material.dart';

import 'dot.dart';

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        double o(int i) {
          final t = (_a.value + i * 0.18) % 1.0;
          final v = (t < 0.5) ? (t * 2) : ((1 - t) * 2);
          return 0.25 + v * 0.75;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Dot(opacity: o(0)),
            const SizedBox(width: 5),
            Dot(opacity: o(1)),
            const SizedBox(width: 5),
            Dot(opacity: o(2)),
          ],
        );
      },
    );
  }
}
