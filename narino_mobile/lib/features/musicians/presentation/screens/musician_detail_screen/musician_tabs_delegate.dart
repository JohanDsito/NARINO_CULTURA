import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';

class MusicianTabsDelegate extends SliverPersistentHeaderDelegate {
  const MusicianTabsDelegate();

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return ColoredBox(
      color: context.nc.bg,
      child: const TabBar(tabs: [Tab(text: 'Obras'), Tab(text: 'Reseñas')]),
    );
  }

  @override
  bool shouldRebuild(covariant MusicianTabsDelegate old) => false;
}
