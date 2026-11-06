import 'package:flutter/material.dart';


class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}
