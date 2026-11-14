import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../musicians/domain/musician_model.dart';
import '../../../musicians/presentation/providers/musician_provider.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/disciplinas.dart';
import 'edit_profile_screen/disciplina_selector.dart';
import 'edit_profile_screen/edit_profile_chip.dart';
import 'edit_profile_screen/edit_profile_header.dart';
import 'edit_profile_screen/edit_profile_section.dart';

/// Clave: valor que espera el backend. Valor: etiqueta visible.
const _kAgrupaciones = <String, String>{
  'SOLISTA': 'Solista',
  'DUO': 'Dúo',
  'TRIO': 'Trío',
  'BANDA': 'Banda',
  'COLECTIVO': 'Colectivo',
  'DJ': 'DJ',
};

/// Convierte lo que escribe la persona en una URL que acepte el backend
/// (`URLField`): agrega `https://` y entiende `@usuario` en Instagram/TikTok.
String normalizarEnlace(String red, String texto) {
  var v = texto.trim();
  if (v.isEmpty) return '';
  if (v.startsWith('@')) {
    final user = v.substring(1);
    switch (red) {
      case 'instagram':
        return 'https://instagram.com/$user';
      case 'tiktok':
        return 'https://www.tiktok.com/@$user';
      case 'facebook':
        return 'https://facebook.com/$user';
    }
  }
  if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(v)) {
    v = 'https://$v';
  }
  return v;
}

bool _enlaceValido(String url) {
  if (url.isEmpty) return true;
  final u = Uri.tryParse(url);
  return u != null && u.host.contains('.') && !url.contains(' ');
}

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

  void _opcionesFoto() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _elegirFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () {
                Navigator.pop(ctx);
                _elegirFoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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

  Future<bool> _confirmarSalida() async {
    if (!_dirty) return true;
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text('Los cambios que hiciste se van a perder.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Seguir editando')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir')),
        ],
      ),
    );
    return salir == true;
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
              EditProfileSection(
                titulo: 'Sobre ti',
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 120,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: esArtista ? 'Nombre artístico' : 'Nombre',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Escribe cómo quieres que te vean'
                        : null,
                  ),
                  if (esArtista) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ciudadCtrl,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Municipio (opcional)',
                        hintText: 'Ej.: Pasto, Ipiales, Tumaco',
                        prefixIcon: Icon(Icons.place_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bioCtrl,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Biografía (opcional)',
                        hintText: 'Tu historia, tu técnica, lo que te inspira…',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ],
              ),
              if (esArtista) ...[
                const SizedBox(height: 16),
                EditProfileSection(
                  titulo: 'Tu disciplina',
                  children: [
                    DisciplinaSelector(
                      valor: _disciplina,
                      onChanged: (v) {
                        setState(() {
                          _disciplina = v;
                          _faltaDisciplina = false;
                          _dirty = true;
                        });
                        if (esDisciplinaMusical(v)) _cargarMusica();
                      },
                    ),
                    if (_faltaDisciplina) ...[
                      const SizedBox(height: 8),
                      Text('Elige tu disciplina',
                          style:
                              AppTypography.bodySmall(color: nc.tomateA.ink)),
                    ],
                  ],
                ),
              ],
              if (esArtista && esMusica) ...[
                const SizedBox(height: 16),
                EditProfileSection(
                  titulo: 'Perfil musical',
                  icon: Icons.music_note_rounded,
                  accent: nc.musica,
                  children: [
                    Text('¿Cómo te presentas?',
                        style: AppTypography.labelSemiBold(
                            color: nc.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in _kAgrupaciones.entries)
                          EditProfileChip(
                            label: e.value,
                            selected: _agrupacion == e.key,
                            accent: nc.musica,
                            onTap: () => setState(() {
                              _agrupacion = e.key;
                              _dirty = true;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Géneros',
                        style: AppTypography.labelSemiBold(
                            color: nc.textSecondary)),
                    const SizedBox(height: 8),
                    if (_cargandoGeneros)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_todosGeneros.isEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: Text('No pudimos cargar los géneros.',
                                style: AppTypography.bodySmall(
                                    color: nc.textMuted)),
                          ),
                          TextButton(
                              onPressed: _cargarMusica,
                              child: const Text('Reintentar')),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in _todosGeneros)
                            EditProfileChip(
                              label: g.name,
                              selected: _generos.contains(g.id),
                              accent: nc.musica,
                              check: true,
                              onTap: () => setState(() {
                                _generos.contains(g.id)
                                    ? _generos.remove(g.id)
                                    : _generos.add(g.id);
                                _dirty = true;
                              }),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
              if (esArtista) ...[
                const SizedBox(height: 16),
                EditProfileSection(
                  titulo: 'Tus redes',
                  subtitulo: 'Pega el enlace o escribe tu @usuario.',
                  children: [
                    for (final red in _links.keys) ...[
                      TextFormField(
                        controller: _links[red],
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: _nombreRed(red),
                          hintText: _ejemploRed(red),
                          prefixIcon: Icon(_iconoRed(red)),
                        ),
                        validator: (v) =>
                            _enlaceValido(normalizarEnlace(red, v ?? ''))
                                ? null
                                : 'Revisa el enlace',
                      ),
                      if (red != _links.keys.last) const SizedBox(height: 12),
                    ],
                  ],
                ),
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

  static String _nombreRed(String k) => switch (k) {
        'website' => 'Sitio web',
        'instagram' => 'Instagram',
        'facebook' => 'Facebook',
        _ => 'TikTok',
      };

  static String _ejemploRed(String k) => switch (k) {
        'website' => 'tusitio.com',
        'facebook' => 'facebook.com/tu.pagina',
        _ => '@tuusuario',
      };

  static IconData _iconoRed(String k) => switch (k) {
        'website' => Icons.language_rounded,
        'instagram' => Icons.camera_alt_outlined,
        'facebook' => Icons.facebook_rounded,
        _ => Icons.music_video_outlined,
      };
}
