import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../musicians/presentation/screens/musicians_screen.dart';
import '../providers/music_discovery_provider.dart';

class MusicDiscoveryScreen extends ConsumerStatefulWidget {
  const MusicDiscoveryScreen({super.key});

  @override
  ConsumerState<MusicDiscoveryScreen> createState() =>
      _MusicDiscoveryScreenState();
}

class _MusicDiscoveryScreenState extends ConsumerState<MusicDiscoveryScreen> {
  final _queryCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _queryCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search() {
    _focusNode.unfocus();
    ref.read(musicDiscoveryProvider.notifier).search(_queryCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicDiscoveryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Descubrimiento Musical',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: Column(
        children: [
          // ── Header banner ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.indigoNoche,
                  AppColors.indigoClaro.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.oroClaro, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Búsqueda inteligente',
                      style:
                          AppTypography.labelSemiBold(color: AppColors.oroClaro),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Describe el tipo de música que buscas y te recomendaremos artistas de Nariño.',
                  style: AppTypography.bodySmall(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryCtrl,
                        focusNode: _focusNode,
                        style: AppTypography.bodyMedium(color: Colors.white),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText:
                              'Ej: música andina tradicional, rock nariñense...',
                          hintStyle:
                              AppTypography.bodySmall(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.oroClaro, width: 1.5),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          suffixIcon: _queryCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.white70, size: 18),
                                  onPressed: () {
                                    setState(_queryCtrl.clear);
                                    ref
                                        .read(musicDiscoveryProvider.notifier)
                                        .clear();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.oroClaro,
                          foregroundColor: AppColors.obsidiana,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.obsidiana,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Suggestions ───────────────────────────────────────────────────
          if (!state.hasSearched)
            _SuggestionsPanel(
              textPrimary: textPrimary,
              textMuted: textMuted,
              onSuggestion: (s) {
                _queryCtrl.text = s;
                setState(() {});
                ref.read(musicDiscoveryProvider.notifier).search(s);
              },
            ),

          // ── Results ───────────────────────────────────────────────────────
          if (state.hasSearched)
            Expanded(
              child: _ResultsBody(
                state: state,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cs: cs,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Suggestion chips ─────────────────────────────────────────────────────────

const _kSuggestions = [
  'Música andina de Nariño',
  'Chirimía del Pacífico',
  'Cumbia nariñense',
  'Trova pastusa',
  'Rock alternativo Pasto',
  'Jazz fusión andino',
];

class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    required this.textPrimary,
    required this.textMuted,
    required this.onSuggestion,
  });

  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Búsquedas sugeridas',
              style: AppTypography.labelSemiBold(color: textPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kSuggestions.map((s) {
                return ActionChip(
                  label: Text(s,
                      style: AppTypography.caption(
                          color: AppColors.indigoClaro)),
                  onPressed: () => onSuggestion(s),
                  backgroundColor:
                      AppColors.indigoClaro.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: AppColors.indigoClaro.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: AppColors.indigoClaro),
                const SizedBox(width: 6),
                Text('Consejos', style: AppTypography.labelSemiBold(color: textPrimary)),
              ],
            ),
            const SizedBox(height: 10),
            _Tip(
              icon: Icons.music_note_outlined,
              text:
                  'Describe el género, ritmo o estado de ánimo que buscas.',
              textMuted: textMuted,
            ),
            const SizedBox(height: 8),
            _Tip(
              icon: Icons.place_outlined,
              text:
                  'Menciona una ciudad o región de Nariño para resultados locales.',
              textMuted: textMuted,
            ),
            const SizedBox(height: 8),
            _Tip(
              icon: Icons.people_outline,
              text:
                  'Indica si buscas solistas, dúos o agrupaciones musicales.',
              textMuted: textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({
    required this.icon,
    required this.text,
    required this.textMuted,
  });

  final IconData icon;
  final String text;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: AppTypography.bodySmall(color: textMuted)),
        ),
      ],
    );
  }
}

// ─── Results body ─────────────────────────────────────────────────────────────

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({
    required this.state,
    required this.textPrimary,
    required this.textMuted,
    required this.cs,
  });

  final MusicDiscoveryState state;
  final Color textPrimary;
  final Color textMuted;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.indigoClaro),
            SizedBox(height: 16),
            Text('Buscando artistas...'),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.indigoClaro),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Error al buscar',
                style: AppTypography.bodyMedium(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_outlined, size: 48, color: textMuted),
              const SizedBox(height: 12),
              Text(
                'No se encontraron músicos para\n"${state.lastQuery}"',
                style: AppTypography.bodyMedium(color: textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${state.results.length} músico${state.results.length == 1 ? '' : 's'} encontrado${state.results.length == 1 ? '' : 's'}',
            style: AppTypography.caption(color: textMuted),
          ),
        ),
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                MusicianCard(musician: state.results[i]),
          ),
        ),
      ],
    );
  }
}
