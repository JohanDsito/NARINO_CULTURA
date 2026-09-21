import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../musicians/data/musician_repository.dart';
import '../../../musicians/domain/musician_model.dart';
import '../../../profile/data/profile_repository.dart';
import 'artistic_profile_screen/discipline.dart';
import 'artistic_profile_screen/discipline_card.dart';
import 'artistic_profile_screen/error_banner.dart';

// ─── Disciplinas disponibles ─────────────────────────────────────────────────

const _kDisciplines = <Discipline>[
  Discipline(
    label: 'Artesano',
    value: 'Artesano',
    icon: Icons.content_cut_outlined,
    description: 'Objetos únicos con técnicas tradicionales',
  ),
  Discipline(
    label: 'Fotógrafo',
    value: 'Fotógrafo',
    icon: Icons.camera_alt_outlined,
    description: 'Captura momentos y paisajes del territorio',
  ),
  Discipline(
    label: 'Escultor',
    value: 'Escultor',
    icon: Icons.architecture_outlined,
    description: 'Formas tridimensionales en diferentes materiales',
  ),
  Discipline(
    label: 'Pintor',
    value: 'Pintor',
    icon: Icons.brush_outlined,
    description: 'Expresión visual sobre lienzo u otras superficies',
  ),
  Discipline(
    label: 'Músico',
    value: 'Música',
    icon: Icons.music_note_outlined,
    description: 'Composición, interpretación y producción musical',
  ),
];

/// Clave: valor que espera el backend. Valor: etiqueta visible al usuario.
const _kAggregationTypes = <String, String>{
  'SOLISTA': 'Solista',
  'DUO': 'Dúo',
  'TRIO': 'Trío',
  'BANDA': 'Banda',
  'COLECTIVO': 'Colectivo',
  'DJ': 'DJ',
};

// ─── Pantalla ────────────────────────────────────────────────────────────────

class ArtisticProfileScreen extends StatefulWidget {
  const ArtisticProfileScreen({super.key});

  @override
  State<ArtisticProfileScreen> createState() => _ArtisticProfileScreenState();
}

class _ArtisticProfileScreenState extends State<ArtisticProfileScreen> {
  final _profileRepo = ProfileRepository();
  final _musicianRepo = MusicianRepository();

  // Step 0 state
  String? _selected;
  bool _isLoading = false;
  String? _error;
  String _firstName = 'Artista';

  // Step 1 (músico) state
  int _step = 0;
  final _artisticNameCtrl = TextEditingController();
  String? _aggregationType;
  List<MusicGenreModel> _genres = [];
  final Set<int> _selectedGenreIds = {};
  bool _loadingGenres = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  @override
  void dispose() {
    _artisticNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final profile = await _profileRepo.getMyProfile();
      if (profile != null) {
        _firstName =
            profile.nombreArtistico.isNotEmpty ? profile.nombreArtistico : 'Artista';
        final discipline = profile.disciplina;
        if (discipline.isNotEmpty && mounted) {
          if (discipline == 'Música') {
            final musician = await _musicianRepo.getMyProfile();
            if (musician != null) {
              if (!mounted) return;
              context.go('/home');
              return;
            }
            _artisticNameCtrl.text = _firstName;
            if (mounted) setState(() { _step = 1; _isLoading = false; });
            _fetchGenres();
            return;
          }
          if (mounted) context.go('/home');
          return;
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGenres() async {
    setState(() => _loadingGenres = true);
    try {
      final genres = await _musicianRepo.getGenres();
      if (mounted) {
        setState(() {
          _genres = genres;
          _loadingGenres = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGenres = false);
    }
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await _profileRepo.updateMyProfile(disciplina: _selected);

      if (!mounted) return;

      if (_selected == 'Música') {
        _artisticNameCtrl.text = _firstName;
        _fetchGenres();
        setState(() { _step = 1; _isLoading = false; });
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo guardar el perfil. Intenta de nuevo.';
        });
      }
    }
  }

  Future<void> _saveMusicianProfile() async {
    final name = _artisticNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // Verificar si ya existe un perfil de músico (para hacer PATCH en vez de POST)
      final existing = await _musicianRepo.getMyProfile();

      await _musicianRepo.saveMyProfile(
        artisticName: name,
        aggregationType: _aggregationType,
        genreIds: _selectedGenreIds.toList(),
        existingSlug: existing?.slug,
      );

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1) return _buildMusicianStep(context);
    return _buildDisciplineStep(context);
  }

  // ── Step 0: Selección de disciplina ─────────────────────────────────────────

  Widget _buildDisciplineStep(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              title: '¿Cuál es tu perfil artístico?',
              subtitle: 'Elige la disciplina que mejor te describe.',
            ),
            Expanded(
              child: _isLoading && _selected == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        children: [
                          for (final d in _kDisciplines) ...[
                            DisciplineCard(
                              discipline: d,
                              isSelected: _selected == d.value,
                              disabled: _isLoading,
                              onTap: () => setState(() => _selected = d.value),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 4),
                            ErrorBanner(message: _error!),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: (_selected == null || _isLoading) ? null : _confirm,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Text('Continuar'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading ? null : () => context.go('/home'),
                            child: Text(
                              'Completar más tarde',
                              style: AppTypography.bodySmall(color: textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Perfil musical ───────────────────────────────────────────────────

  Widget _buildMusicianStep(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              title: 'Tu perfil musical',
              subtitle: 'Cuéntanos más sobre tu propuesta musical.',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre artístico
                    Text(
                      'Nombre artístico *',
                      style: AppTypography.labelSemiBold(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _artisticNameCtrl,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mic_outlined),
                        hintText: 'Nombre con el que te conocen',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tipo de agrupación
                    Text(
                      'Tipo de agrupación',
                      style: AppTypography.labelSemiBold(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _aggregationType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.group_outlined),
                        hintText: 'Selecciona una opción',
                      ),
                      items: _kAggregationTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: _isLoading
                          ? null
                          : (v) => setState(() => _aggregationType = v),
                    ),
                    const SizedBox(height: 20),

                    // Géneros musicales
                    Text(
                      'Géneros musicales',
                      style: AppTypography.labelSemiBold(color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona los géneros que defines tu música.',
                      style: AppTypography.caption(color: textMuted),
                    ),
                    const SizedBox(height: 10),
                    _loadingGenres
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _genres.isEmpty
                            ? Text(
                                'No se pudieron cargar los géneros.',
                                style: AppTypography.caption(color: textMuted),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _genres.map((g) {
                                  final selected = _selectedGenreIds.contains(g.id);
                                  return FilterChip(
                                    label: Text(g.name),
                                    selected: selected,
                                    onSelected: _isLoading
                                        ? null
                                        : (_) => setState(() {
                                              if (selected) {
                                                _selectedGenreIds.remove(g.id);
                                              } else {
                                                _selectedGenreIds.add(g.id);
                                              }
                                            }),
                                    selectedColor: cs.primary.withValues(alpha: 0.15),
                                    checkmarkColor: cs.primary,
                                    labelStyle: AppTypography.bodySmall(
                                      color: selected ? cs.primary : textPrimary,
                                    ),
                                  );
                                }).toList(),
                              ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveMusicianProfile,
                        child: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : const Text('Finalizar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/home'),
                      child: Text(
                        'Completar más tarde',
                        style: AppTypography.bodySmall(color: textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header compartido ────────────────────────────────────────────────────────

  Widget _buildHeader({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      color: AppColors.obsidiana,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.oroAndino,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_outlined,
                    size: 22, color: AppColors.obsidiana),
              ),
              const SizedBox(width: 12),
              Text(
                'Nariño Cultura',
                style: AppTypography.displayBold(color: AppColors.oroClaro)
                    .copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.quoteItalic(
              color: AppColors.oroClaro.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}

