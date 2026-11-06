import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../data/musician_repository.dart';
import '../providers/musician_provider.dart';

/// Tipos del backend (`MusicalWork.WorkType`).
const _kTipos = <String, (String, IconData)>{
  'VIDEO': ('Video musical', Icons.smart_display_outlined),
  'LIVE': ('En vivo', Icons.mic_external_on_outlined),
  'STUDIO': ('Estudio', Icons.album_outlined),
  'COVER': ('Cover', Icons.repeat_rounded),
  'PODCAST': ('Podcast', Icons.podcasts_rounded),
};

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

  /// "3:45" → 225. También acepta solo segundos ("225").
  int? _segundos(String t) {
    final v = t.trim();
    if (v.isEmpty) return null;
    if (v.contains(':')) {
      final p = v.split(':');
      final m = int.tryParse(p[0]);
      final s = int.tryParse(p.length > 1 ? p[1] : '0');
      if (m == null || s == null || s > 59) return null;
      return m * 60 + s;
    }
    return int.tryParse(v);
  }

  String? _validarUrl(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    return Uri.tryParse(t)?.hasScheme == true ? null : 'Debe empezar por https://';
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
        if (_segundos(_durationCtrl.text) != null)
          'duration_seconds': _segundos(_durationCtrl.text),
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
    final nc = context.nc;
    Widget titulo(String t, {String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t,
                  style: AppTypography.labelSemiBold(color: nc.textPrimary)),
              if (hint != null)
                Text(hint,
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
            ],
          ),
        );

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
            NcCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titulo('¿Qué vas a compartir?'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in _kTipos.entries)
                        ChoiceChip(
                          avatar: Icon(e.value.$2,
                              size: 16,
                              color: _workType == e.key
                                  ? nc.musica.onFill
                                  : nc.musica.ink),
                          label: Text(e.value.$1),
                          selected: _workType == e.key,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _workType = e.key),
                          selectedColor: nc.musica.fill,
                          side: BorderSide(
                              color: _workType == e.key
                                  ? nc.musica.fill
                                  : nc.border),
                          labelStyle: AppTypography.labelMedium(
                            color: _workType == e.key
                                ? nc.musica.onFill
                                : nc.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ponle un título'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionCtrl,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.event_rounded, size: 18),
                          label: Text(_releaseDate == null
                              ? 'Lanzamiento'
                              : '${_releaseDate!.day}/${_releaseDate!.month}/'
                                  '${_releaseDate!.year}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Duración',
                            hintText: '3:45',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty ||
                                  _segundos(v!) != null
                              ? null
                              : 'Usa min:seg',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NcCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titulo('¿Dónde se puede escuchar?',
                      hint: 'Agrega al menos un enlace para que el público '
                          'pueda reproducirla.'),
                  TextFormField(
                    controller: _youtubeCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'YouTube',
                      prefixIcon: Icon(Icons.smart_display_outlined),
                    ),
                    validator: _validarUrl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _spotifyCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Spotify',
                      prefixIcon: Icon(Icons.graphic_eq_rounded),
                    ),
                    validator: _validarUrl,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _soundcloudCtrl,
                    decoration: const InputDecoration(
                      labelText: 'SoundCloud (enlace o código para insertar)',
                      prefixIcon: Icon(Icons.cloud_outlined),
                    ),
                  ),
                ],
              ),
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
