import 'package:flutter/material.dart';

/// Curva "spring" del design system: `cubic-bezier(0.175, 0.885, 0.32, 1.1)`.
const Curve kNcSpring = Cubic(0.175, 0.885, 0.32, 1.1);

/// Transición estándar: `cubic-bezier(0.25, 1, 0.5, 1)`.
const Curve kNcEase = Cubic(0.25, 1, 0.5, 1);

/// Reacciona al toque encogiéndose un poco (como `:active { scale(.96) }`).
class NcPressable extends StatefulWidget {
  const NcPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? semanticLabel;

  @override
  State<NcPressable> createState() => _NcPressableState();
}

class _NcPressableState extends State<NcPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
          curve: kNcSpring,
          child: widget.child,
        ),
      ),
    );
  }
}
