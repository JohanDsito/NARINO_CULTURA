import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

class ProfileOptionGroup extends StatelessWidget {
  const ProfileOptionGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return NcCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      gradientBorder: false,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 66, color: nc.border),
            children[i],
          ],
        ],
      ),
    );
  }
}
