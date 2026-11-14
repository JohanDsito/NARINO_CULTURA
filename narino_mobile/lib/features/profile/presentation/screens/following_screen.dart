import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/profile_provider.dart';
import 'following_screen/following_empty_state.dart';
import 'following_screen/following_tile.dart';

enum _Filtro { todos, artistas, musicos }

/// Artistas y músicos que sigue la persona.
class FollowingScreen extends ConsumerStatefulWidget {
  const FollowingScreen({super.key});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  _Filtro _filtro = _Filtro.todos;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final async = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Siguiendo')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          NcEmptyState(
            icon: Icons.wifi_off_rounded,
            accent: nc.tomateA,
            title: 'No pudimos cargar a quién sigues',
            message: 'Revisa tu conexión e intenta de nuevo.',
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(followingProvider),
          ),
        ]),
        data: (todos) {
          if (todos.isEmpty) return const FollowingEmptyState();
          final artistas = todos.where((p) => !p.esMusico).length;
          final musicos = todos.length - artistas;
          final lista = switch (_filtro) {
            _Filtro.todos => todos,
            _Filtro.artistas => todos.where((p) => !p.esMusico).toList(),
            _Filtro.musicos => todos.where((p) => p.esMusico).toList(),
          };
          return RefreshIndicator(
            onRefresh: () => ref.refresh(followingProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (artistas > 0 && musicos > 0) ...[
                  SegmentedButton<_Filtro>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: _Filtro.todos,
                          label: Text('Todos ${todos.length}')),
                      ButtonSegment(
                          value: _Filtro.artistas,
                          label: Text('Artistas $artistas')),
                      ButtonSegment(
                          value: _Filtro.musicos,
                          label: Text('Música $musicos')),
                    ],
                    selected: {_filtro},
                    onSelectionChanged: (s) =>
                        setState(() => _filtro = s.first),
                  ),
                  const SizedBox(height: 16),
                ] else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                    child: Text(
                      todos.length == 1
                          ? 'Sigues a 1 perfil'
                          : 'Sigues a ${todos.length} perfiles',
                      style: AppTypography.bodySmall(color: nc.textSecondary),
                    ),
                  ),
                for (final p in lista) ...[
                  FollowingTile(perfil: p),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
