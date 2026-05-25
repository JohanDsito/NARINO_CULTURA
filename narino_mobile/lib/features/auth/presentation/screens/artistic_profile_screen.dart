import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

// ─── Disciplinas disponibles ─────────────────────────────────────────────────

class _Discipline {
  const _Discipline({
    required this.label,
    required this.value,
    required this.icon,
    required this.description,
  });

  final String label;
  final String value;
  final IconData icon;
  final String description;
}

const _kDisciplines = <_Discipline>[
  _Discipline(
    label: 'Artesano',
    value: 'Artesano',
    icon: Icons.content_cut_outlined,
    description: 'Objetos únicos con técnicas tradicionales',
  ),
  _Discipline(
    label: 'Fotógrafo',
    value: 'Fotógrafo',
    icon: Icons.camera_alt_outlined,
    description: 'Captura momentos y paisajes del territorio',
  ),
  _Discipline(
    label: 'Escultor',
    value: 'Escultor',
    icon: Icons.architecture_outlined,
    description: 'Formas tridimensionales en diferentes materiales',
  ),
  _Discipline(
    label: 'Pintor',
    value: 'Pintor',
    icon: Icons.brush_outlined,
    description: 'Expresión visual sobre lienzo u otras superficies',
  ),
  _Discipline(
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
  // Step 0 state
  String? _selected;
  bool _isLoading = false;
  String? _error;
  String _userId = '';
  String _firstName = 'Artista';
  String? _existingSlug;

  // Step 1 (músico) state
  int _step = 0;
  final _artisticNameCtrl = TextEditingController();
  String? _aggregationType;
  List<Map<String, dynamic>> _genres = [];
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

  Future<Map<String, dynamic>?> _findMyArtist(dynamic dio, String userId) async {
    String? pageUrl = '/api/v1/artists/?page_size=100';
    while (pageUrl != null) {
      final res = await dio.get(pageUrl);
      final List<dynamic> artists;
      String? nextPage;
      if (res.data is Map) {
        final data = res.data as Map;
        final raw = data['results'];
        artists = raw is List ? raw : [];
        final next = data['next']?.toString();
        nextPage = (next != null && next.isNotEmpty) ? next : null;
      } else if (res.data is List) {
        artists = res.data as List;
        nextPage = null;
      } else {
        break;
      }
      for (final a in artists) {
        if (a is Map && a['user_id']?.toString() == userId) {
          return Map<String, dynamic>.from(a);
        }
      }
      pageUrl = nextPage;
    }
    return null;
  }

  Future<void> _loadExisting() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = ApiClient.instance.dio;

      final userRes = await dio.get('/api/v1/users/me/');
      final userData = userRes.data as Map<String, dynamic>;
      _userId = userData['id']?.toString() ?? '';
      _firstName = userData['first_name']?.toString() ??
          userData['nombre']?.toString() ??
          'Artista';

      final found = await _findMyArtist(dio, _userId);
      if (found != null) {
        _existingSlug = found['slug']?.toString();
        final discipline = found['discipline']?.toString() ?? '';
        if (discipline.isNotEmpty && mounted) {
          if (discipline == 'Música') {
            try {
              await dio.get('/api/v1/musicians/me/');
              if (!mounted) return;
              context.go('/home');
              return;
            } catch (_) {
              _artisticNameCtrl.text = _firstName;
              if (mounted) setState(() { _step = 1; _isLoading = false; });
              _fetchGenres();
              return;
            }
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
      final res = await ApiClient.instance.dio.get('/api/v1/musicians/genres/');
      final data = res.data;
      List<dynamic> raw = [];
      if (data is List) raw = data;
      if (data is Map && data['results'] is List) raw = data['results'] as List;
      if (mounted) {
        setState(() {
          _genres = raw
              .whereType<Map>()
              .map((g) => {'id': g['id'], 'name': g['name']?.toString() ?? ''})
              .toList()
              .cast<Map<String, dynamic>>();
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
      final dio = ApiClient.instance.dio;

      if (_existingSlug == null || _existingSlug!.isEmpty) {
        final found = await _findMyArtist(dio, _userId);
        _existingSlug = found?['slug']?.toString();
      }

      if (_existingSlug != null && _existingSlug!.isNotEmpty) {
        await dio.patch(
          '/api/v1/artists/$_existingSlug/',
          data: {'discipline': _selected},
        );
      } else {
        final res = await dio.post(
          '/api/v1/artists/',
          data: {'artistic_name': _firstName, 'discipline': _selected},
        );
        _existingSlug = (res.data as Map?)?['slug']?.toString();
      }

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
      final dio = ApiClient.instance.dio;

      // Verificar si ya existe un perfil de músico (para hacer PATCH en vez de POST)
      String? musicianSlug;
      try {
        final meRes = await dio.get('/api/v1/musicians/me/');
        musicianSlug = (meRes.data as Map?)?['slug']?.toString();
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        // 404 = no existe aún, se creará con POST
      }

      final payload = <String, dynamic>{
        'artistic_name': name,
        if (_aggregationType != null) 'aggregation_type': _aggregationType,
        if (_selectedGenreIds.isNotEmpty) 'genre_ids': _selectedGenreIds.toList(),
      };

      if (musicianSlug != null && musicianSlug.isNotEmpty) {
        await dio.patch('/api/v1/musicians/$musicianSlug/', data: payload);
      } else {
        await dio.post('/api/v1/musicians/', data: payload);
      }

      if (mounted) context.go('/home');
    } on DioException catch (e) {
      final body = e.response?.data;
      String msg = 'No se pudo guardar el perfil musical. Intenta de nuevo.';
      if (body is Map) {
        final detail = body['detail']?.toString() ?? '';
        if (detail.isNotEmpty) {
          msg = detail;
        } else {
          for (final v in body.values) {
            if (v is List && v.isNotEmpty) { msg = v.first.toString(); break; }
            if (v is String && v.isNotEmpty) { msg = v; break; }
          }
        }
      } else if (body is String && body.isNotEmpty) {
        msg = body;
      }
      if (mounted) setState(() { _isLoading = false; _error = msg; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _error = 'Error inesperado. Intenta de nuevo.'; });
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
                            _DisciplineCard(
                              discipline: d,
                              isSelected: _selected == d.value,
                              disabled: _isLoading,
                              onTap: () => setState(() => _selected = d.value),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 4),
                            _ErrorBanner(message: _error!),
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
                                  final id = (g['id'] as num?)?.toInt() ?? 0;
                                  final name = g['name'] as String;
                                  final selected = _selectedGenreIds.contains(id);
                                  return FilterChip(
                                    label: Text(name),
                                    selected: selected,
                                    onSelected: _isLoading
                                        ? null
                                        : (_) => setState(() {
                                              if (selected) {
                                                _selectedGenreIds.remove(id);
                                              } else {
                                                _selectedGenreIds.add(id);
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
                      _ErrorBanner(message: _error!),
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

// ─── Tarjeta de disciplina ────────────────────────────────────────────────────

class _DisciplineCard extends StatelessWidget {
  const _DisciplineCard({
    required this.discipline,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final _Discipline discipline;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final selectedBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.12)
                    : (isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                discipline.icon,
                size: 24,
                color: isSelected ? cs.primary : textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discipline.label,
                    style: AppTypography.labelSemiBold(
                      color: isSelected ? cs.primary : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    discipline.description,
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.check_circle, color: cs.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner de error ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
