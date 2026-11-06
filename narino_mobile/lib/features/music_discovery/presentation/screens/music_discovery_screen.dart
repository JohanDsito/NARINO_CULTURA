import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../musicians/presentation/widgets/musica_ui.dart';
import '../providers/music_discovery_provider.dart';

const _sugerencias = [
  'Música andina de Nariño',
  'Chirimía del Pacífico',
  'Cumbia nariñense',
  'Trova pastusa',
  'Rock alternativo en Pasto',
  'Jazz fusión andino',
];

/// Descubrimiento musical con IA: describe lo que quieres escuchar.
class MusicDiscoveryScreen extends ConsumerStatefulWidget {
  const MusicDiscoveryScreen({super.key});

  @override
  ConsumerState<MusicDiscoveryScreen> createState() =>
      _MusicDiscoveryScreenState();
}

class _MusicDiscoveryScreenState extends ConsumerState<MusicDiscoveryScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _buscar([String? texto]) {
    if (texto != null) _ctrl.text = texto;
    _focus.unfocus();
    ref.read(musicDiscoveryProvider.notifier).search(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(musicDiscoveryProvider);
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: nc.border),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.canPop() ? context.pop() : context.go('/musicians');
      },
      child: Scaffold(
        backgroundColor: nc.bg,
        appBar: AppBar(title: const Text('Descubre tu sonido')),
        body: Stack(
          children: [
            const Positioned.fill(child: CarnavalBackground()),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                NcCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 18, color: nc.oroA.ink),
                          const SizedBox(width: 6),
                          Text('BÚSQUEDA INTELIGENTE',
                              style: AppTypography.kicker(color: nc.oroA.ink)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('¿Qué quieres escuchar hoy?',
                          style:
                              AppTypography.displayBold(color: nc.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        'Descríbelo con tus palabras: un ritmo, un momento o '
                        'una emoción. Te recomendamos artistas de Nariño.',
                        style: AppTypography.bodyMedium(color: nc.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscar(),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Ej.: algo andino y tranquilo para la tarde',
                          prefixIcon: const Icon(Icons.graphic_eq_rounded),
                          suffixIcon: _ctrl.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Borrar',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _ctrl.clear();
                                    setState(() {});
                                    ref
                                        .read(musicDiscoveryProvider.notifier)
                                        .clear();
                                  },
                                ),
                          border: pill,
                          enabledBorder: pill,
                          focusedBorder: pill.copyWith(
                              borderSide:
                                  BorderSide(color: nc.musica.fill, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      NcPrimaryButton(
                        label: 'Recomiéndame',
                        icon: Icons.auto_awesome_rounded,
                        loading: state.isLoading,
                        onPressed:
                            _ctrl.text.trim().isEmpty ? null : () => _buscar(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!state.hasSearched) ...[
                  Text('Prueba con',
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _sugerencias.length; i++)
                        ActionChip(
                          label: Text(_sugerencias[i]),
                          onPressed: () => _buscar(_sugerencias[i]),
                          backgroundColor: [
                            nc.musica.tint,
                            nc.magentaA.tint,
                            nc.naranjaA.tint,
                          ][i % 3],
                          side: BorderSide(color: nc.border),
                          labelStyle:
                              AppTypography.labelMedium(color: nc.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ] else if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.hasError)
                  NcEmptyState(
                    icon: Icons.cloud_off_rounded,
                    accent: nc.tomateA,
                    title: 'No pudimos recomendarte ahora',
                    message: state.errorMessage!,
                    actionLabel: 'Reintentar',
                    onAction: () => _buscar(state.lastQuery),
                    padding: EdgeInsets.zero,
                  )
                else if (state.results.isEmpty)
                  NcEmptyState(
                    icon: Icons.search_off_rounded,
                    accent: nc.musica,
                    title: 'Sin coincidencias',
                    message: 'Prueba describiéndolo de otra forma o con un '
                        'género más amplio.',
                    padding: EdgeInsets.zero,
                  )
                else ...[
                  Text('Para "${state.lastQuery}"',
                      style:
                          AppTypography.displaySemiBold(color: nc.textPrimary)),
                  const SizedBox(height: 12),
                  for (final m in state.results)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MusicoCard(musician: m),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
