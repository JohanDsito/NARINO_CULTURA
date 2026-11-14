import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../musicians/domain/musician_model.dart';
import '../../../musicians/presentation/providers/musician_provider.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/disciplinas.dart';
import 'edit_profile_screen/edit_profile_header.dart';
import '../../../../shared/widgets/dialogs/confirmar_accion.dart';
import '../../../../shared/widgets/dialogs/elegir_origen_foto.dart';
import 'edit_profile_screen/edit_profile_about_section.dart';
import 'edit_profile_screen/edit_profile_discipline_section.dart';
import 'edit_profile_screen/edit_profile_links_section.dart';
import 'edit_profile_screen/edit_profile_music_section.dart';
import 'edit_profile_screen/enlaces.dart';

// Las pruebas y otras pantallas usan normalizarEnlace desde aquí.
export 'edit_profile_screen/enlaces.dart' show normalizarEnlace;

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _links = {
    'website': TextEditingController(),
    'instagram': TextEditingController(),
    'facebook': TextEditingController(),
    'tiktok': TextEditingController(),
  };
  final _picker = ImagePicker();

  String? _disciplina;
  bool _faltaDisciplina = false;
  File? _nuevaFoto;
  bool _initialized = false;
  bool _dirty = false;
  bool _guardando = false;

  // Perfil musical
  String? _agrupacion;
  final Set<int> _generos = {};
  List<MusicGenreModel> _todosGeneros = [];
  bool _cargandoGeneros = false;
  String? _musicianSlug;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (esDisciplinaMusical(
          ref.read(myProfileProvider).profile?.disciplina)) {
        _cargarMusica();
      }
    });
  }

  void _initFrom(ProfileModel p) {
    if (_initialized) return;
    _nombreCtrl.text = p.nombreArtistico;
    _bioCtrl.text = p.biografia ?? '';
    _ciudadCtrl.text = p.ciudad ?? '';
    for (final e in _links.entries) {
      e.value.text = p.redesSociales[e.key] ?? '';
    }
    _disciplina = p.disciplina.trim().isEmpty ? null : p.disciplina;
    _initialized = true;
  }

  void _marcar() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _cargarMusica() async {
    if (_cargandoGeneros || _todosGeneros.isNotEmpty) return;
    setState(() => _cargandoGeneros = true);
    final repo = ref.read(musicianRepositoryProvider);
    try {
      final r = await Future.wait([repo.getGenres(), repo.getMyProfile()]);
      final generos = r[0] as List<MusicGenreModel>;
      final existente = r[1] as MusicianModel?;
      if (existente != null) {
        _musicianSlug = existente.slug;
        _agrupacion = existente.aggregationType;
        // El músico trae solo los nombres de sus géneros: se cruzan con la
        // lista completa para recuperar los IDs.
        for (final g in generos) {
          if (existente.genres.contains(g.name)) _generos.add(g.id);
        }
      }
      if (mounted) setState(() => _todosGeneros = generos);
    } catch (_) {
      // Se muestra el aviso de "no se pudieron cargar".
    } finally {
      if (mounted) setState(() => _cargandoGeneros = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _bioCtrl.dispose();
    _ciudadCtrl.dispose();
    for (final c in _links.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFoto(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;
    final ext = picked.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usa una imagen JPG o PNG.')));
      }
      return;
    }
    setState(() {
      _nuevaFoto = File(picked.path);
      _dirty = true;
    });
  }

  Future<void> _opcionesFoto() async {
    final origen = await elegirOrigenFoto(context);
    if (origen != null) await _elegirFoto(origen);
  }

  bool _esArtista(String? role) => role == 'artista' || role == null;

  Future<void> _guardar() async {
    final role = ref.read(currentUserRoleProvider).valueOrNull;
    final pideDisciplina = _esArtista(role);
    final formOk = _formKey.currentState!.validate();
    setState(() => _faltaDisciplina = pideDisciplina && _disciplina == null);
    if (!formOk || _faltaDisciplina) return;

    final profile = ref.read(myProfileProvider).profile;
    final fotoAnterior = profile?.fotoUrl;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _guardando = true);

    final ok = await ref.read(myProfileProvider.notifier).updateProfile(
          nombreArtistico: _nombreCtrl.text.trim(),
          disciplina: _disciplina ?? '',
          biografia: _bioCtrl.text.trim(),
          ciudad: _ciudadCtrl.text.trim(),
          foto: _nuevaFoto,
          redesSociales: {
            for (final e in _links.entries)
              e.key: normalizarEnlace(e.key, e.value.text),
          },
          artistId: profile?.id,
        );
    if (!mounted) return;

    if (!ok) {
      setState(() => _guardando = false);
      return; // El error se muestra en el aviso de la pantalla.
    }

    // El avatar se pinta con CachedNetworkImage: se limpia esa caché.
    if (_nuevaFoto != null && fotoAnterior != null) {
      await CachedNetworkImage.evictFromCache(fotoAnterior);
    }

    var musicaOk = true;
    if (esDisciplinaMusical(_disciplina)) musicaOk = await _guardarMusica();
    if (!mounted) return;

    ref.invalidate(myMusicianSlugProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(musicaOk
          ? 'Tu perfil quedó actualizado'
          : 'Guardamos tu perfil, pero no tu información musical. '
              'Intenta de nuevo en un momento.'),
    ));
    _salir();
  }

  /// Cierra sin volver a preguntar: `canPop` se lee al construir, así que se
  /// reconstruye primero y se cierra en el siguiente cuadro.
  void _salir() {
    setState(() {
      _dirty = false;
      _guardando = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  Future<bool> _guardarMusica() async {
    final repo = ref.read(musicianRepositoryProvider);
    try {
      _musicianSlug ??= (await repo.getMyProfile())?.slug;
      final saved = await repo.saveMyProfile(
        artisticName: _nombreCtrl.text.trim(),
        aggregationType: _agrupacion,
        genreIds: _generos.toList(),
        existingSlug: _musicianSlug,
      );
      _musicianSlug = saved.slug;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _confirmarSalida() async =>
      !_dirty ||
      await confirmarAccion(
        context,
        titulo: '¿Salir sin guardar?',
        mensaje: 'Los cambios que hiciste se van a perder.',
        cancelar: 'Seguir editando',
        confirmar: 'Salir',
      );

  void _elegirDisciplina(String v) {
    setState(() {
      _disciplina = v;
      _faltaDisciplina = false;
      _dirty = true;
    });
    if (esDisciplinaMusical(v)) _cargarMusica();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final state = ref.watch(myProfileProvider);
    if (state.profile != null) _initFrom(state.profile!);
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final esArtista = _esArtista(role);
    final esMusica = esDisciplinaMusical(_disciplina);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmarSalida() && mounted) _salir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar perfil'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Form(
          key: _formKey,
          onChanged: _marcar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              EditProfileHeader(
                nombre: _nombreCtrl,
                disciplina: _disciplina,
                foto: _nuevaFoto,
                fotoUrl: state.profile?.fotoUrl,
                onFoto: _opcionesFoto,
              ),
              const SizedBox(height: 20),
              if (state.hasError && !_guardando) ...[
                NcBanner.error(
                    context,
                    state.errorMessage ??
                        'No se pudieron guardar los cambios.'),
                const SizedBox(height: 16),
              ],
              EditProfileAboutSection(
                nombre: _nombreCtrl,
                ciudad: _ciudadCtrl,
                bio: _bioCtrl,
                esArtista: esArtista,
                onNombreChanged: () => setState(() {}),
              ),
              if (esArtista) ...[
                const SizedBox(height: 16),
                EditProfileDisciplineSection(
                  valor: _disciplina,
                  falta: _faltaDisciplina,
                  onChanged: _elegirDisciplina,
                ),
              ],
              if (esArtista && esMusica) ...[
                const SizedBox(height: 16),
                EditProfileMusicSection(
                  agrupacion: _agrupacion,
                  generos: _generos,
                  todosGeneros: _todosGeneros,
                  cargando: _cargandoGeneros,
                  onAgrupacion: (a) => setState(() {
                    _agrupacion = a;
                    _dirty = true;
                  }),
                  onGenero: (id) => setState(() {
                    _generos.contains(id)
                        ? _generos.remove(id)
                        : _generos.add(id);
                    _dirty = true;
                  }),
                  onReintentar: _cargarMusica,
                ),
              ],
              if (esArtista) ...[
                const SizedBox(height: 16),
                EditProfileLinksSection(links: _links),
              ],
            ],
          ),
        ),
        bottomNavigationBar: NcGlassBottomBar(
          child: NcPrimaryButton(
            label: 'Guardar cambios',
            icon: Icons.check_rounded,
            loading: _guardando || state.isSaving,
            onPressed: _guardar,
          ),
        ),
      ),
    );
  }
}
