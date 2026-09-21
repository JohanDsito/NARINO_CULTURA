import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/music_discovery_provider.dart';
import 'music_discovery_screen/results_body.dart';
import 'music_discovery_screen/suggestions_panel.dart';

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/musicians');
          }
        }
      },
      child: Scaffold(
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
            SuggestionsPanel(
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
              child: ResultsBody(
                state: state,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cs: cs,
              ),
            ),
        ],
      ),
      ),
    );
  }
}
