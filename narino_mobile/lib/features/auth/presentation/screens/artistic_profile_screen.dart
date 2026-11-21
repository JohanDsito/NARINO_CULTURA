import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../musicians/data/musician_repository.dart';
import '../../../musicians/domain/musician_model.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/widgets/disciplinas.dart';
import '../widgets/auth_scaffold.dart';
import 'artistic_profile_screen/disciplina_tile.dart';
import 'artistic_profile_screen/musician_step_form.dart';

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
                  DisciplinaTile(
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
          MusicianStepForm(
            nombre: _artisticNameCtrl,
            nombreError: _nameError,
            onNombreChanged: () {
              if (_nameError) setState(() => _nameError = false);
            },
            agrupacion: _aggregationType,
            onAgrupacion: (v) => setState(() => _aggregationType = v),
            generos: _genres,
            seleccionados: _selectedGenreIds,
            cargandoGeneros: _loadingGenres,
            onGenero: (id) => setState(() {
              _selectedGenreIds.contains(id)
                  ? _selectedGenreIds.remove(id)
                  : _selectedGenreIds.add(id);
            }),
            enabled: !_isLoading,
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
