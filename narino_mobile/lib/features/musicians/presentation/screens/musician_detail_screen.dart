import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/musician_provider.dart';
import 'musician_detail_screen/musician_profile_header.dart';

class MusicianDetailScreen extends ConsumerWidget {
  const MusicianDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    return ref.watch(musicianDetailProvider(slug)).when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Músico')),
            body: ListView(children: [
              NcEmptyState(
                icon: Icons.music_off_outlined,
                accent: nc.tomateA,
                title: 'No pudimos abrir este perfil',
                message: e.toString(),
                actionLabel: 'Reintentar',
                onAction: () => ref.invalidate(musicianDetailProvider(slug)),
              ),
            ]),
          ),
          data: (m) => MusicianProfileHeader(musician: m),
        );
  }
}
