import 'package:flutter/material.dart';

// ─── Estado de carga ──────────────────────────────────────────────────────────

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(
          child: CircularProgressIndicator(
            color: cs.primary,
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }
}
