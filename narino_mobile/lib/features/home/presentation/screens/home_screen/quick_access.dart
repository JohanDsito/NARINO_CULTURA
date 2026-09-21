import 'package:flutter/material.dart';

import '../home_screen.dart';
import 'quick_tile.dart';

// ─── Acceso rápido ────────────────────────────────────────────────────────────

class QuickAccess extends StatelessWidget {
  const QuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
        ),
        itemCount: kQuickItems.length,
        itemBuilder: (context, i) => QuickTile(item: kQuickItems[i]),
      ),
    );
  }
}
