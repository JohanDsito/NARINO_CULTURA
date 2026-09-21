import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../musicians/data/musician_repository.dart';
import '../../../musicians/domain/musician_model.dart';
import '../../domain/profile_model.dart';
import '../../domain/profile_state.dart';
import '../providers/profile_provider.dart';
import '../../../../core/providers/user_role_provider.dart';
import 'edit_profile_screen/section_divider.dart';

/// Clave: valor que espera el backend. Valor: etiqueta visible al usuario.
const _kAggregationTypes = <String, String>{
  'SOLISTA': 'Solista',
  'DUO': 'Dúo',
  'TRIO': 'Trío',
  'BANDA': 'Banda',
  'COLECTIVO': 'Colectivo',
  'DJ': 'DJ',
};

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _musicianRepo = MusicianRepository();

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  final _ttCtrl = TextEditingController();
  final _webCtrl = TextEditingController();

  String? _disciplina;
  File? _nuevaFoto;
  bool _initialized = false;
  bool _showPreview = false;

  // Campos exclusivos de músico
  String? _aggregationType;
  final Set<int> _selectedGenreIds = {};
  List<MusicGenreModel> _genres = [];
  bool _loadingGenres = false;
  String? _musicianSlug;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMusicianData());
  }

  void _initFrom(ProfileModel p) {
    if (_initialized) return;
    _nombreCtrl.text = p.nombreArtistico;
    _bioCtrl.text = p.biografia ?? '';
    _igCtrl.text = p.redesSociales['instagram'] ?? '';
    _fbCtrl.text = p.redesSociales['facebook'] ?? '';
    _ttCtrl.text = p.redesSociales['tiktok'] ?? '';
    _webCtrl.text = p.redesSociales['website'] ?? '';
    _disciplina = p.disciplina;
    _initialized = true;
  }

  Future<void> _loadMusicianData() async {
    final profile = ref.read(myProfileProvider).profile;
    if (profile?.disciplina != 'Música') return;
    await _fetchMusicianFields();
  }

  Future<void> _fetchMusicianFields() async {
    if (_loadingGenres) return;
    setState(() => _loadingGenres = true);
    try {
      // Cargar géneros disponibles y el perfil de músico existente (si hay)
      // para pre-rellenar los campos, en paralelo.
      final results = await Future.wait([
        _musicianRepo.getGenres(),
        _musicianRepo.getMyProfile(),
      ]);
      final genres = results[0] as List<MusicGenreModel>;
      final existing = results[1] as MusicianModel?;

      if (existing != null) {
        _musicianSlug = existing.slug;
        _aggregationType = existing.aggregationType;
        // El modelo del músico solo trae los nombres de sus géneros; se
        // cruzan contra la lista completa para recuperar sus IDs.
        for (final g in genres) {
          if (existing.genres.contains(g.name)) _selectedGenreIds.add(g.id);
        }
      }

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

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _bioCtrl.dispose();
    _igCtrl.dispose();
    _fbCtrl.dispose();
    _ttCtrl.dispose();
    _webCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;
    final ext = picked.path.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solo se permiten imágenes JPG o PNG.')),
        );
      }
      return;
    }
    setState(() => _nuevaFoto = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final role = ref.read(currentUserRoleProvider).value;
    final needsDisciplina = role == 'artista' || role == 'admin' || role == null;
    final disciplina = _disciplina;
    if (needsDisciplina && (disciplina == null || disciplina.isEmpty)) return;

    final profile = ref.read(myProfileProvider).profile;
    final oldFotoUrl = profile?.fotoUrl;

    final redesSociales = <String, String>{
      'instagram': _igCtrl.text.trim(),
      'facebook': _fbCtrl.text.trim(),
      'tiktok': _ttCtrl.text.trim(),
      'website': _webCtrl.text.trim(),
    };

    final ok = await ref.read(myProfileProvider.notifier).updateProfile(
          nombreArtistico: _nombreCtrl.text.trim(),
          disciplina: disciplina ?? '',
          biografia: _bioCtrl.text.trim(),
          foto: _nuevaFoto,
          redesSociales: redesSociales,
          artistId: profile?.id,
        );

    if (!mounted) return;

    if (ok) {
      if (_nuevaFoto != null && oldFotoUrl != null) {
        imageCache.evict(NetworkImage(oldFotoUrl));
      }

      if (disciplina == 'Música') {
        await _saveMusicianData();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppColors.selvaAndina));
      context.pop();
    } else {
      final errMsg = ref.read(myProfileProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errMsg ?? 'No se pudieron guardar los cambios'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _saveMusicianData() async {
    try {
      // Resolver slug si no lo tenemos aún
      _musicianSlug ??= (await _musicianRepo.getMyProfile())?.slug;

      final saved = await _musicianRepo.saveMyProfile(
        artisticName: _nombreCtrl.text.trim(),
        aggregationType: _aggregationType,
        genreIds: _selectedGenreIds.toList(),
        existingSlug: _musicianSlug,
      );
      _musicianSlug = saved.slug;
    } catch (_) {
      // Silencioso: el perfil artístico ya se guardó; el musical es best-effort
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProfileProvider);
    if (state.profile != null) _initFrom(state.profile!);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Editar perfil',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro)
              .copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.oroClaro),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showPreview = !_showPreview),
            child: Text(_showPreview ? 'Editar' : 'Vista previa',
                style: AppTypography.labelMedium(color: AppColors.oroClaro)),
          )
        ],
      ),
      body: _showPreview ? _buildPreview(state.profile) : _buildForm(state),
    );
  }

  Widget _buildPreview(ProfileModel? profile) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border)),
            child: Column(
              children: [
                AppAvatar(
                  radius: 48,
                  file: _nuevaFoto,
                  url: _nuevaFoto == null ? profile?.fotoUrl : null,
                  initials: _nombreCtrl.text.isNotEmpty
                      ? _nombreCtrl.text
                      : '?',
                  backgroundColor:
                      isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida,
                  initialsColor: cs.primary,
                ),
                const SizedBox(height: 12),
                Text(
                    _nombreCtrl.text.isEmpty
                        ? 'Nombre artístico'
                        : _nombreCtrl.text,
                    style: AppTypography.displaySemiBold(color: textPrimary)),
                Text(_disciplina ?? '',
                    style: AppTypography.quoteItalic(color: textMuted)),
                if (_disciplina == 'Música' && _aggregationType != null) ...[
                  const SizedBox(height: 4),
                  Text(_aggregationType!,
                      style: AppTypography.caption(color: textMuted)),
                ],
                if (_bioCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_bioCtrl.text,
                      style: AppTypography.bodyMedium(color: textSecondary),
                      textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Esta es la vista previa de tu perfil público.',
              style: AppTypography.caption(color: textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
                onPressed: _save,
                child: Text('Guardar cambios',
                    style: AppTypography.buttonText(color: cs.onPrimary))),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ProfileState state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final role = ref.watch(currentUserRoleProvider).value;
    final showDisciplina = role == 'artista' || role == 'admin' || role == null;
    final isMusico = _disciplina == 'Música';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    AppAvatar(
                      radius: 52,
                      file: _nuevaFoto,
                      url: _nuevaFoto == null ? state.profile?.fotoUrl : null,
                      initials: _nombreCtrl.text.isNotEmpty
                          ? _nombreCtrl.text
                          : '?',
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: cs.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
                child: Text('JPG/PNG · máx. 5 MB',
                    style: AppTypography.caption(color: textMuted))),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nombreCtrl,
              style: AppTypography.bodyMedium(color: textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Nombre artístico *',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre artístico es obligatorio'
                  : null,
            ),
            const SizedBox(height: 14),

            if (showDisciplina) ...[
              DropdownButtonFormField<String>(
                initialValue: _disciplina,
                decoration: const InputDecoration(
                    labelText: 'Disciplina *',
                    prefixIcon: Icon(Icons.brush_outlined)),
                style: AppTypography.bodyMedium(color: textPrimary),
                items: ArtisticDisciplines.all
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _disciplina = v);
                  if (v == 'Música' && _genres.isEmpty && !_loadingGenres) {
                    _fetchMusicianFields();
                  }
                },
                validator: (v) => v == null ? 'Selecciona una disciplina' : null,
              ),
              const SizedBox(height: 14),
            ],

            TextFormField(
              controller: _bioCtrl,
              maxLines: 5,
              maxLength: 500,
              style: AppTypography.bodyMedium(color: textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Biografía (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 4),

            // ── Campos exclusivos de músico ──────────────────────────────────
            if (isMusico) ...[
              const SizedBox(height: 10),
              SectionDivider(label: 'Perfil musical', textMuted: textMuted),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _aggregationType,
                decoration: const InputDecoration(
                    labelText: 'Tipo de agrupación',
                    prefixIcon: Icon(Icons.group_outlined)),
                style: AppTypography.bodyMedium(color: textPrimary),
                items: _kAggregationTypes.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _aggregationType = v),
              ),
              const SizedBox(height: 14),

              Text('Géneros musicales',
                  style: AppTypography.labelSemiBold(color: textSecondary)),
              const SizedBox(height: 8),
              if (_loadingGenres)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_genres.isEmpty)
                Text('No se pudieron cargar los géneros.',
                    style: AppTypography.caption(color: textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _genres.map((g) {
                    final selected = _selectedGenreIds.contains(g.id);
                    return FilterChip(
                      label: Text(g.name),
                      selected: selected,
                      onSelected: (_) => setState(() {
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
              const SizedBox(height: 14),
            ],

            // ── Redes sociales ───────────────────────────────────────────────
            SectionDivider(label: 'Redes sociales', textMuted: textMuted),
            const SizedBox(height: 10),
            TextFormField(
                controller: _webCtrl,
                keyboardType: TextInputType.url,
                style: AppTypography.bodyMedium(color: textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Sitio web (URL)',
                    prefixIcon: Icon(Icons.language_outlined))),
            const SizedBox(height: 10),
            TextFormField(
                controller: _igCtrl,
                keyboardType: TextInputType.url,
                style: AppTypography.bodyMedium(color: textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Instagram (URL)',
                    prefixIcon: Icon(Icons.camera_alt_outlined))),
            const SizedBox(height: 10),
            TextFormField(
                controller: _fbCtrl,
                keyboardType: TextInputType.url,
                style: AppTypography.bodyMedium(color: textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Facebook (URL)',
                    prefixIcon: Icon(Icons.facebook_outlined))),
            const SizedBox(height: 10),
            TextFormField(
                controller: _ttCtrl,
                keyboardType: TextInputType.url,
                style: AppTypography.bodyMedium(color: textPrimary),
                decoration: const InputDecoration(
                    labelText: 'TikTok (URL)',
                    prefixIcon: Icon(Icons.music_note_outlined))),
            const SizedBox(height: 28),

            if (state.hasError) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3))),
                child: Text(state.errorMessage!,
                    style: AppTypography.bodySmall(color: AppColors.error)),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : _save,
                child: state.isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: cs.onPrimary,
                          strokeWidth: 2,
                        ))
                    : Text('Guardar cambios',
                        style: AppTypography.buttonText(color: cs.onPrimary)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
