import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../providers/musician_provider.dart';
import 'musical_work_card.dart';

// ─── Obras ──────────────────────────────────────────────────────────────────

class MusicianWorksTab extends ConsumerWidget {
  const MusicianWorksTab({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    return ref.watch(musicianWorksProvider(slug)).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            NcEmptyState(
              icon: Icons.cloud_off_rounded,
              accent: nc.tomateA,
              title: 'No pudimos cargar las obras',
              message: e.toString(),
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(musicianWorksProvider(slug)),
            ),
          ]),
          data: (obras) => obras.isEmpty
              ? ListView(children: [
                  NcEmptyState(
                    icon: Icons.library_music_outlined,
                    accent: nc.musica,
                    title: 'Aún no hay obras',
                    message: 'Cuando publique canciones o videos, aparecerán '
                        'aquí.',
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: obras.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => MusicalWorkCard(obra: obras[i]),
                ),
        );
  }
}
