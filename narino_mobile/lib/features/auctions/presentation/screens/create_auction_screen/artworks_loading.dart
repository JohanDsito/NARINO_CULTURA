import 'package:flutter/material.dart';

class ArtworksLoading extends StatelessWidget {
  const ArtworksLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
      ),
    );
  }
}
