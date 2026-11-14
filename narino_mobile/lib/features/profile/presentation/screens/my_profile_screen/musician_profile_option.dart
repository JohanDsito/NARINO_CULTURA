import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../musicians/presentation/providers/musician_provider.dart';
import 'profile_option_tile.dart';

class MusicianProfileOption extends ConsumerWidget {
  const MusicianProfileOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final slug = ref.watch(myMusicianSlugProvider);
    return slug.when(
      loading: () => ProfileOptionTile(
        icon: Icons.music_note_rounded,
        accent: nc.musica,
        title: 'Mi perfil de músico',
        subtitle: 'Cargando…',
        onTap: () {},
      ),
      error: (_, __) => ProfileOptionTile(
        icon: Icons.music_note_rounded,
        accent: nc.musica,
        title: 'Mi perfil de músico',
        subtitle: 'Toca para reintentar',
        onTap: () => ref.invalidate(myMusicianSlugProvider),
      ),
      data: (s) => s == null
          ? ProfileOptionTile(
              icon: Icons.library_add_outlined,
              accent: nc.musica,
              title: 'Completar perfil musical',
              subtitle: 'Agrega tu formato y géneros',
              onTap: () => context.push('/artistic-profile'),
            )
          : ProfileOptionTile(
              icon: Icons.music_note_rounded,
              accent: nc.musica,
              title: 'Mi perfil de músico',
              subtitle: 'Obras, reseñas y seguidores',
              onTap: () => context.push('/musicians/$s'),
            ),
    );
  }
}
