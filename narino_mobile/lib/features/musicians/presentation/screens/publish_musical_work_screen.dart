import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/design/design.dart';
import '../../data/musician_repository.dart';
import '../providers/musician_provider.dart';
import 'publish_musical_work_screen/duracion.dart';
import 'publish_musical_work_screen/obra_musical_datos_section.dart';
import 'publish_musical_work_screen/obra_musical_enlaces_section.dart';

/// Publicar una obra musical con enlaces para escucharla (acento azul).
class PublishMusicalWorkScreen extends ConsumerStatefulWidget {
  const PublishMusicalWorkScreen({super.key});

  @override
  ConsumerState<PublishMusicalWorkScreen> createState() =>
      _PublishMusicalWorkScreenState();
}

class _PublishMusicalWorkScreenState
    extends ConsumerState<PublishMusicalWorkScreen> {
  final _musicianRepo = MusicianRepository();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _soundcloudCtrl = TextEditingController();
  final _spotifyCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String? _workType = 'STUDIO';
  DateTime? _releaseDate;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _youtubeCtrl.dispose();
    _soundcloudCtrl.dispose();
    _spotifyCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _releaseDate = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final slug = (await _musicianRepo.getMyProfile())?.slug;
      if (slug == null || slug.isEmpty) {
        setState(() {
          _isSaving = false;
          _error = 'Primero completa tu perfil musical.';
        });
        return;
      }
      final d = _releaseDate;
      await _musicianRepo.addWork(slug, {
        'title': _titleCtrl.text.trim(),
        if (_workType != null) 'work_type': _workType,
        if (_descriptionCtrl.text.trim().isNotEmpty)
          'description': _descriptionCtrl.text.trim(),
        if (_youtubeCtrl.text.trim().isNotEmpty)
          'youtube_url': _youtubeCtrl.text.trim(),
        if (_soundcloudCtrl.text.trim().isNotEmpty)
          'soundcloud_embed': _soundcloudCtrl.text.trim(),
        if (_spotifyCtrl.text.trim().isNotEmpty)
          'spotify_track_url': _spotifyCtrl.text.trim(),
        if (d != null)
          'release_date': '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}',
        if (segundosDeDuracion(_durationCtrl.text) != null)
          'duration_seconds': segundosDeDuracion(_durationCtrl.text),
      });
      if (!mounted) return;
      ref.invalidate(musicianWorksProvider(slug));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Tu obra ya está en tu perfil!')));
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Subir obra musical'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            ObraMusicalDatosSection(
              tipo: _workType,
              onTipo: (t) => setState(() => _workType = t),
              titulo: _titleCtrl,
              descripcion: _descriptionCtrl,
              lanzamiento: _releaseDate,
              onElegirFecha: _pickDate,
              duracion: _durationCtrl,
            ),
            const SizedBox(height: 16),
            ObraMusicalEnlacesSection(
              youtube: _youtubeCtrl,
              spotify: _spotifyCtrl,
              soundcloud: _soundcloudCtrl,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              NcBanner.error(context, _error!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: NcGlassBottomBar(
        child: NcPrimaryButton(
          label: 'Publicar obra',
          icon: Icons.library_music_outlined,
          loading: _isSaving,
          onPressed: _submit,
        ),
      ),
    );
  }
}
