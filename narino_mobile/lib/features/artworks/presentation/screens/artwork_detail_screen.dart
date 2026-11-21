import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';
import 'artwork_detail_screen/artwork_detail_body.dart';
import 'artwork_detail_screen/error_view.dart';
import 'artwork_detail_screen/loading_view.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class ArtworkDetailScreen extends ConsumerWidget {
  const ArtworkDetailScreen({
    super.key,
    required this.artworkId,
    this.initialArtwork,
  });

  final String artworkId;
  final ArtworkModel? initialArtwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialArtwork != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ArtworkDetailBody(artwork: initialArtwork!),
      );
    }

    final asyncArtwork = ref.watch(artworkDetailProvider(artworkId));

    return asyncArtwork.when(
      data: (artwork) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ArtworkDetailBody(artwork: artwork),
      ),
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const LoadingView(),
      ),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}
