import 'package:flutter/material.dart';

import 'stat_card.dart';

class StatGrid extends StatelessWidget {
  const StatGrid({
    super.key,
    required this.visitasMes,
    required this.visitasTotal,
    required this.nuevosSeguidores,
  });

  final int visitasMes;
  final int visitasTotal;
  final int nuevosSeguidores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(label: 'Visitas este mes', value: '$visitasMes'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(label: 'Visitas total', value: '$visitasTotal'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Nuevos seguidores',
                value: '$nuevosSeguidores',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}
