import 'dart:async';

import 'package:flutter/widgets.dart';

/// Cuenta regresiva que se redibuja sola cada segundo (solo este widget, no
/// la pantalla completa). Se detiene al llegar a cero.
class NcCountdown extends StatefulWidget {
  const NcCountdown({
    super.key,
    required this.target,
    required this.builder,
    this.onFinished,
  });

  final DateTime target;
  final Widget Function(BuildContext context, Duration remaining) builder;
  final VoidCallback? onFinished;

  /// `2d 4h`, `03:12:09` o `00:00:00`.
  static String format(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours.remainder(24)}h';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:'
        '${two(d.inSeconds.remainder(60))}';
  }

  /// Texto para lectores de pantalla: "2 días 4 horas", "12 minutos"…
  static String spoken(Duration d) {
    if (d == Duration.zero) return 'finalizada';
    if (d.inDays >= 1) {
      return '${d.inDays} días ${d.inHours.remainder(24)} horas';
    }
    if (d.inHours >= 1) {
      return '${d.inHours} horas ${d.inMinutes.remainder(60)} minutos';
    }
    return '${d.inMinutes} minutos ${d.inSeconds.remainder(60)} segundos';
  }

  @override
  State<NcCountdown> createState() => _NcCountdownState();
}

class _NcCountdownState extends State<NcCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  Duration _calc() {
    final d = widget.target.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  void _start() {
    _timer?.cancel();
    _remaining = _calc();
    if (_remaining == Duration.zero) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final r = _calc();
      setState(() => _remaining = r);
      if (r == Duration.zero) {
        _timer?.cancel();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(NcCountdown old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}
