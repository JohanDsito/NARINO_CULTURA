import 'package:flutter/material.dart';

// ─── Vista de carga ───────────────────────────────────────────────────────────

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
        strokeWidth: 2,
      ),
    );
  }
}
