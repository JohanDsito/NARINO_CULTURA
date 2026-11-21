import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

class CatalogSkeletonCard extends StatefulWidget {
  const CatalogSkeletonCard({super.key});

  @override
  State<CatalogSkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<CatalogSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    reduce ? _c.stop() : _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final block = nc.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: block,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
        child: Container(
          decoration: BoxDecoration(
            color: nc.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: nc.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Container(color: block)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(110, 12),
                    const SizedBox(height: 8),
                    bar(70, 10),
                    const SizedBox(height: 10),
                    bar(60, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
