import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../musicians/presentation/providers/musician_provider.dart';
import 'menu_section.dart';
import 'menu_tile.dart';
import 'section_label.dart';

// ─── Sección exclusiva para músicos ──────────────────────────────────────────

class MusicianSection extends ConsumerWidget {
  const MusicianSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slugAsync = ref.watch(myMusicianSlugProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(label: 'Mi perfil musical'),
        MenuSection(children: [
          slugAsync.when(
            data: (slug) => slug != null
                ? MenuTile(
                    icon: Icons.mic_outlined,
                    title: 'Mi perfil de músico',
                    subtitle: 'Ver tus obras, reseñas y seguidores',
                    onTap: () => context.push('/musicians/$slug'),
                  )
                : MenuTile(
                    icon: Icons.mic_outlined,
                    title: 'Completar perfil musical',
                    subtitle: 'Agrega géneros y tipo de agrupación',
                    onTap: () => context.push('/profile/edit'),
                  ),
            loading: () => MenuTile(
              icon: Icons.mic_outlined,
              title: 'Mi perfil de músico',
              subtitle: 'Cargando...',
              onTap: () {},
            ),
            error: (_, __) => MenuTile(
              icon: Icons.mic_outlined,
              title: 'Mi perfil de músico',
              subtitle: 'No disponible',
              onTap: () => ref.invalidate(myMusicianSlugProvider),
            ),
          ),
          MenuTile(
            icon: Icons.library_music_outlined,
            title: 'Publicar obra musical',
            subtitle: 'Agrega canciones, videos o grabaciones',
            onTap: () => context.push('/musicians/works/publish'),
          ),
          MenuTile(
            icon: Icons.explore_outlined,
            title: 'Descubrimiento musical',
            subtitle: 'Explora músicos y géneros de Nariño',
            onTap: () => context.push('/music-discovery'),
          ),
        ]),
      ],
    );
  }
}
