import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/artwork_card.dart';
import '../home_screen.dart';
import 'for_you_header.dart';

// ─── Sección "Para ti" ────────────────────────────────────────────────────────

class ForYouSection extends StatelessWidget {
  const ForYouSection({required this.ref, super.key});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncReco = ref.watch(homeAiArtworkRecommendationsProvider(6));

    return asyncReco.when(
      loading: () => const ForYouHeader(loading: true),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final items = list.take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ForYouHeader(loading: false),
            SizedBox(
              height: 184,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 160,
                  child: ArtworkCard(artwork: items[i], compact: true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
