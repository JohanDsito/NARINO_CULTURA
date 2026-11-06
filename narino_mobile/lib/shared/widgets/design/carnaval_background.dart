import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nc_theme.dart';

/// Desplazamiento vertical de la pantalla visible, para el parallax del fondo.
/// El shell lo actualiza con el scroll de la pestaña activa.
final ValueNotifier<double> carnavalScrollOffset = ValueNotifier<double>(0);

/// Fondo "carnaval" (liviano para móvil): orbes difuminados, formas
/// culturales (sol, nota, lente) y partículas de talco que se mueven a
/// distintas velocidades con el scroll.
///
/// Los orbes se pintan con degradados radiales en vez de `blur` para no
/// costar rendimiento.
class CarnavalBackground extends StatefulWidget {
  const CarnavalBackground({super.key, this.scrollOffset});

  /// Si es `null` usa [carnavalScrollOffset].
  final ValueListenable<double>? scrollOffset;

  @override
  State<CarnavalBackground> createState() => _CarnavalBackgroundState();
}

class _CarnavalBackgroundState extends State<CarnavalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final offset = widget.scrollOffset ?? carnavalScrollOffset;

    final orbOpacity = nc.isDark ? 0.45 : 0.28;
    final shapeColor = nc.isDark
        ? nc.oro.withValues(alpha: 0.15)
        : nc.textPrimary.withValues(alpha: 0.05);
    final lenteColor = nc.isDark
        ? nc.azul.withValues(alpha: 0.15)
        : nc.textPrimary.withValues(alpha: 0.05);
    final notaColor = nc.isDark
        ? nc.magenta.withValues(alpha: 0.15)
        : nc.textPrimary.withValues(alpha: 0.05);

    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: LayoutBuilder(builder: (context, c) {
            // Igual que `inset: -60px`: el lienzo sobresale 60 px por lado.
            final w = c.maxWidth + 120;
            final h = c.maxHeight + 120;

            Widget layer(double speed, Widget child) {
              if (reduce) return child;
              return ValueListenableBuilder<double>(
                valueListenable: offset,
                builder: (_, y, ch) => Transform.translate(
                  offset: Offset(0, -y * speed),
                  child: ch,
                ),
                child: child,
              );
            }

            return OverflowBox(
              maxWidth: w,
              maxHeight: h,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Orbes ──
                    _orb(layer, 0.04, left: -40, top: 0, size: 280,
                        color: AppColors.tomate, opacity: orbOpacity),
                    _orb(layer, -0.06, right: -60, top: h * 0.48, size: 240,
                        color: AppColors.naranjaNeon, opacity: orbOpacity),
                    _orb(layer, 0.03, left: w * 0.10, bottom: -60, size: 320,
                        color: nc.azul,
                        opacity: nc.isDark ? 0.35 : orbOpacity),
                    _orb(layer, -0.05, left: w * 0.35, top: h * 0.28,
                        size: 220, color: nc.magenta,
                        opacity: nc.isDark ? 0.25 : orbOpacity),

                    // ── Formas culturales ──
                    Positioned(
                      top: h * 0.14,
                      right: w * 0.04,
                      child: layer(
                        -0.07,
                        RepaintBoundary(
                          child: RotationTransition(
                            turns: _spin,
                            child: CustomPaint(
                              size: const Size.square(180),
                              painter: _SolPainter(shapeColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.42,
                      left: w * 0.08,
                      child: layer(
                        0.09,
                        CustomPaint(
                          size: const Size.square(90),
                          painter: _NotaPainter(notaColor),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: h * 0.16,
                      left: w * 0.04,
                      child: layer(
                        -0.05,
                        CustomPaint(
                          size: const Size.square(130),
                          painter: _LentePainter(lenteColor),
                        ),
                      ),
                    ),

                    // ── Talco ──
                    for (final p in _talco)
                      Positioned(
                        top: p.top == null ? null : h * p.top!,
                        bottom: p.bottom == null ? null : h * p.bottom!,
                        left: p.left == null ? null : w * p.left!,
                        right: p.right == null ? null : w * p.right!,
                        child: layer(p.speed, _particle(nc, p.size)),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _orb(
    Widget Function(double, Widget) layer,
    double speed, {
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    // El desenfoque de 56 px de la web se imita con un degradado radial que
    // se extiende 56 px más allá del círculo.
    const spread = 56.0;
    final total = size + spread * 2;
    return Positioned(
      left: left == null ? null : left - spread,
      right: right == null ? null : right - spread,
      top: top == null ? null : top - spread,
      bottom: bottom == null ? null : bottom - spread,
      child: layer(
        speed,
        Container(
          width: total,
          height: total,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.75),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
      ),
    );
  }

  Widget _particle(NcColors nc, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: nc.isDark
            ? Colors.white.withValues(alpha: 0.3)
            : AppColors.naranjaNeon.withValues(alpha: 0.2),
        boxShadow: nc.isDark
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
    );
  }
}

class _Talco {
  const _Talco(this.size, this.speed,
      {this.top, this.bottom, this.left, this.right});
  final double size;
  final double speed;
  final double? top, bottom, left, right;
}

const _talco = [
  _Talco(8, -0.12, top: 0.20, left: 0.30),
  _Talco(12, 0.16, top: 0.60, right: 0.20),
  _Talco(6, -0.09, bottom: 0.30, left: 0.40),
  _Talco(10, 0.11, top: 0.40, right: 0.40),
  _Talco(5, 0.13, top: 0.80, left: 0.60),
];

// ─── Formas (mismos trazos que los SVG del diseño) ───────────────────────────

Paint _stroke(Color c, double width) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// viewBox 0 0 100 100: círculo r20 + 8 rayos.
class _SolPainter extends CustomPainter {
  _SolPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final p = _stroke(color, 2 * k);
    canvas.drawCircle(Offset(50 * k, 50 * k), 20 * k, p);
    const rays = [
      [50, 10, 50, 25], [50, 90, 50, 75], [10, 50, 25, 50], [90, 50, 75, 50],
      [22, 22, 32, 32], [78, 78, 68, 68], [22, 78, 32, 68], [78, 22, 68, 32],
    ];
    for (final r in rays) {
      canvas.drawLine(
          Offset(r[0] * k, r[1] * k), Offset(r[2] * k, r[3] * k), p);
    }
  }

  @override
  bool shouldRepaint(_SolPainter old) => old.color != color;
}

/// viewBox 0 0 24 24: corchea doble.
class _NotaPainter extends CustomPainter {
  _NotaPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = _stroke(color, 2 * k);
    final path = Path()
      ..moveTo(9 * k, 18 * k)
      ..lineTo(9 * k, 5 * k)
      ..lineTo(21 * k, 3 * k)
      ..lineTo(21 * k, 16 * k);
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(6 * k, 18 * k), 3 * k, p);
    canvas.drawCircle(Offset(18 * k, 16 * k), 3 * k, p);
  }

  @override
  bool shouldRepaint(_NotaPainter old) => old.color != color;
}

/// viewBox 0 0 100 100: lente de cámara.
class _LentePainter extends CustomPainter {
  _LentePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final p = _stroke(color, 2 * k);
    final c = Offset(50 * k, 50 * k);
    canvas.drawCircle(c, 40 * k, p);
    canvas.drawCircle(c, 25 * k, p);
    const lines = [
      [50, 25, 65, 10], [50, 75, 35, 90], [25, 50, 10, 35], [75, 50, 90, 65],
    ];
    for (final l in lines) {
      canvas.drawLine(
          Offset(l[0] * k, l[1] * k), Offset(l[2] * k, l[3] * k), p);
    }
  }

  @override
  bool shouldRepaint(_LentePainter old) => old.color != color;
}

