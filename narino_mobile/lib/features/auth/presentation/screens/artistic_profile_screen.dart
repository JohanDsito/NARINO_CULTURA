import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../musicians/data/musician_repository.dart';
import '../../../musicians/domain/musician_model.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/widgets/disciplinas.dart';
import '../widgets/auth_scaffold.dart';

/// Clave: valor que espera el backend. Valor: etiqueta visible.
const _kAgrupaciones = <String, String>{
  'SOLISTA': 'Solista',
  'DUO': 'Dúo',
  'TRIO': 'Trío',
  'BANDA': 'Banda',
  'COLECTIVO': 'Colectivo',
  'DJ': 'DJ',
};

/// Bienvenida del artista: elige su disciplina y, si es música, completa su
/// perfil musical (paso 2).
class ArtisticProfileScreen extends StatefulWidget {
  const ArtisticProfileScreen({super.key, this.profileRepo, this.musicianRepo});

  /// Inyectables para pruebas; por defecto los repositorios reales.
  final ProfileRepository? profileRepo;
  final MusicianRepository? musicianRepo;

  @override
  State<ArtisticProfileScreen> createState() => _ArtisticProfileScreenState();
}

class _ArtisticProfileScreenState extends State<ArtisticProfileScreen> {
  late final _profileRepo = widget.profileRepo ?? ProfileRepository();
  late final _musicianRepo = widget.musicianRepo ?? MusicianRepository();

  // Paso 0
  String? _selected;
  bool _isLoading = false;
  bool _initialLoading = true;
  String? _error;
  String _firstName = 'Artista';

  // Paso 1 (músico)
  int _step = 0;
  bool _cameFromStep0 = false;
  final _artisticNameCtrl = TextEditingController();
  String? _aggregationType;
  List<MusicGenreModel> _genres = [];
  final Set<int> _selectedGenreIds = {};
  bool _loadingGenres = false;
  bool _nameError = false;

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
    try {
      final profile = await _profileRepo.getMyProfile();
      if (profile != null) {
        _firstName = profile.nombreArtistico.isNotEmpty
            ? profile.nombreArtistico
            : 'Artista';
        final discipline = profile.disciplina;
        if (discipline.isNotEmpty && mounted) {
          if (esDisciplinaMusical(discipline)) {
            final musician = await _musicianRepo.getMyProfile();
            if (!mounted) return;
            if (musician != null) {
              context.go('/home');
              return;
            }
            _artisticNameCtrl.text = _firstName;
            setState(() {
              _step = 1;
              _initialLoading = false;
            });
            _fetchGenres();
            return;
          }
          context.go('/home');
          return;
        }
      }
    } catch (_) {
      // Sin perfil previo: se muestra la elección de disciplina.
    }
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _fetchGenres() async {
    setState(() => _loadingGenres = true);
    try {
      final genres = await _musicianRepo.getGenres();
      if (mounted) setState(() => _genres = genres);
    } catch (_) {
      // Se muestra el aviso de "no se pudieron cargar".
    } finally {
      if (mounted) setState(() => _loadingGenres = false);
    }
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _profileRepo.updateMyProfile(disciplina: _selected);
      if (!mounted) return;
      if (esDisciplinaMusical(_selected)) {
        _artisticNameCtrl.text = _firstName;
        _fetchGenres();
        setState(() {
          _step = 1;
          _cameFromStep0 = true;
          _isLoading = false;
        });
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo guardar tu disciplina. Intenta de nuevo.';
        });
      }
    }
  }

  Future<void> _saveMusicianProfile() async {
    final name = _artisticNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
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
  Widget build(BuildContext context) =>
      _step == 1 ? _musicianStep(context) : _disciplineStep(context);

  // ── Paso 0: disciplina ────────────────────────────────────────────────────

  Widget _disciplineStep(BuildContext context) {
    final nc = context.nc;
    return AuthScaffold(
      kicker: 'Bienvenida al carnaval',
      title: '¿Qué creas, $_firstName?',
      subtitle: 'Elige la disciplina que mejor te describe. Podrás cambiarla '
          'después desde tu perfil.',
      footer: TextButton(
        onPressed: _isLoading ? null : () => context.go('/home'),
        child: const Text('Completar más tarde'),
      ),
      child: _initialLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final d in kDisciplinas) ...[
                  _DisciplinaTile(
                    disciplina: d,
                    accent: d.accent(nc),
                    selected: _selected == d.value,
                    onTap: _isLoading
                        ? null
                        : () => setState(() => _selected = d.value),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  NcBanner.error(context, _error!),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                NcPrimaryButton(
                  label: 'Continuar',
                  loading: _isLoading,
                  onPressed: _selected == null ? null : _confirm,
                ),
              ],
            ),
    );
  }

  // ── Paso 1: perfil musical ────────────────────────────────────────────────

  Widget _musicianStep(BuildContext context) {
    final nc = context.nc;
    final musica = nc.tomateA;

    Widget label(String text, {String? hint}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: AppTypography.labelSemiBold(color: nc.textPrimary)
                    .copyWith(fontSize: 14)),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(hint,
                  style: AppTypography.bodySmall(color: nc.textSecondary)),
            ],
          ],
        );

    return AuthScaffold(
      kicker: 'Paso 2 de 2',
      title: 'Tu perfil musical',
      subtitle: 'Cuéntanos cómo suena tu propuesta para que el público te '
          'encuentre.',
      logoAccent: musica,
      onBack: _cameFromStep0 && !_isLoading
          ? () => setState(() => _step = 0)
          : null,
      footer: TextButton(
        onPressed: _isLoading ? null : () => context.go('/home'),
        child: const Text('Completar más tarde'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label('Nombre artístico'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _artisticNameCtrl,
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_nameError) setState(() => _nameError = false);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.mic_none_rounded),
              hintText: 'Nombre con el que te conocen',
              errorText: _nameError ? 'Escribe tu nombre artístico' : null,
            ),
          ),
          const SizedBox(height: 22),
          label('Formato'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _kAgrupaciones.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _aggregationType == e.key,
                  showCheckmark: false,
                  onSelected: _isLoading
                      ? null
                      : (v) =>
                          setState(() => _aggregationType = v ? e.key : null),
                  selectedColor: musica.fill,
                  labelStyle: AppTypography.labelMedium(
                    color: _aggregationType == e.key
                        ? musica.onFill
                        : nc.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                  side: BorderSide(
                    color: _aggregationType == e.key
                        ? musica.fill
                        : nc.border,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          label('Géneros musicales',
              hint: 'Elige todos los que definen tu música.'),
          const SizedBox(height: 10),
          if (_loadingGenres)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_genres.isEmpty)
            NcBanner(
              accent: nc.oroA,
              message: 'No pudimos cargar los géneros. Puedes agregarlos '
                  'luego desde tu perfil.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in _genres)
                  FilterChip(
                    label: Text(g.name),
                    selected: _selectedGenreIds.contains(g.id),
                    onSelected: _isLoading
                        ? null
                        : (_) => setState(() {
                              _selectedGenreIds.contains(g.id)
                                  ? _selectedGenreIds.remove(g.id)
                                  : _selectedGenreIds.add(g.id);
                            }),
                    selectedColor: nc.azulA.tint,
                    checkmarkColor: nc.azul,
                    side: BorderSide(
                      color: _selectedGenreIds.contains(g.id)
                          ? nc.azul
                          : nc.border,
                    ),
                    labelStyle: AppTypography.labelMedium(
                      color: _selectedGenreIds.contains(g.id)
                          ? nc.azul
                          : nc.textPrimary,
                    ),
                  ),
              ],
            ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            NcBanner.error(context, _error!),
          ],
          const SizedBox(height: 24),
          NcPrimaryButton(
            label: 'Finalizar',
            icon: Icons.check_rounded,
            loading: _isLoading,
            onPressed: _saveMusicianProfile,
          ),
        ],
      ),
    );
  }
}

class _DisciplinaTile extends StatelessWidget {
  const _DisciplinaTile({
    required this.disciplina,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final Disciplina disciplina;
  final NcAccent accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${disciplina.label}. ${disciplina.description}',
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(accent.tint, nc.bgCard)
                : nc.itemFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent.fill : nc.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? accent.fill : accent.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  disciplina.icon,
                  size: 22,
                  color: selected ? accent.onFill : accent.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disciplina.label,
                      style: AppTypography.labelSemiBold(
                          color: selected ? accent.ink : nc.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      disciplina.description,
                      style: AppTypography.bodySmall(color: nc.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent.fill : Colors.transparent,
                  border: Border.all(
                    color: selected ? accent.fill : nc.textMuted,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 14, color: accent.onFill)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
