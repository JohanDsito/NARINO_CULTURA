import 'package:flutter/material.dart';

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
        ),
      ],
    );
  }
}
