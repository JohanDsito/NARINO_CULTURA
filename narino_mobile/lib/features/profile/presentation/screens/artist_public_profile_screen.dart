import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/profile_provider.dart';
import 'artist_public_profile_screen/artist_profile_view.dart';

/// Perfil público de un artista (acento magenta: artes plásticas).
class ArtistPublicProfileScreen extends ConsumerWidget {
  const ArtistPublicProfileScreen({super.key, required this.artistId});

  /// Slug del artista.
  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    return ref.watch(artistProfileProvider(artistId)).when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Artista')),
            body: ListView(children: [
              NcEmptyState(
                icon: Icons.person_off_outlined,
                accent: nc.tomateA,
                title: 'No pudimos abrir este perfil',
                message: e.toString(),
                actionLabel: 'Reintentar',
                onAction: () => ref.invalidate(artistProfileProvider(artistId)),
              ),
            ]),
          ),
          data: (p) => ArtistProfileView(profile: p),
        );
  }
}
