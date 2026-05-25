import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/musician_provider.dart';

const _kWorkTypes = <String, String>{
  'VIDEO': 'Video musical',
  'LIVE': 'Presentación en vivo',
  'STUDIO': 'Grabación de estudio',
  'COVER': 'Cover / Versión',
  'PODCAST': 'Podcast / Entrevista',
};

class PublishMusicalWorkScreen extends ConsumerStatefulWidget {
  const PublishMusicalWorkScreen({super.key});

  @override
  ConsumerState<PublishMusicalWorkScreen> createState() =>
      _PublishMusicalWorkScreenState();
}

class _PublishMusicalWorkScreenState
    extends ConsumerState<PublishMusicalWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _soundcloudCtrl = TextEditingController();
  final _spotifyCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String? _workType;
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
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _error = null; });

    try {
      final dio = ApiClient.instance.dio;

      // Obtener slug del músico autenticado
      final meRes = await dio.get('/api/v1/musicians/me/');
      final slug = (meRes.data as Map?)?['slug']?.toString();
      if (slug == null || slug.isEmpty) {
        setState(() {
          _isSaving = false;
          _error = 'No se encontró tu perfil de músico.';
        });
        return;
      }

      final payload = <String, dynamic>{
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
        if (_releaseDate != null)
          'release_date':
              '${_releaseDate!.year.toString().padLeft(4, '0')}-'
              '${_releaseDate!.month.toString().padLeft(2, '0')}-'
              '${_releaseDate!.day.toString().padLeft(2, '0')}',
        if (_durationCtrl.text.trim().isNotEmpty)
          'duration_seconds': int.tryParse(_durationCtrl.text.trim()),
      };

      await dio.post('/api/v1/musicians/$slug/works/add/', data: payload);

      if (mounted) {
        ref.invalidate(musicianWorksProvider(slug));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obra publicada con éxito')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      String msg = 'Error al publicar la obra.';
      final data = e.response?.data;
      if (data is Map) {
        final msgs = <String>[];
        data.forEach((k, v) {
          if (v is List) {
            msgs.addAll(v.map((x) => x.toString()));
          } else {
            msgs.add(v.toString());
          }
        });
        if (msgs.isNotEmpty) msg = msgs.join(' ');
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      if (mounted) setState(() { _isSaving = false; _error = msg; });
    } catch (_) {
      if (mounted) setState(() { _isSaving = false; _error = 'Error inesperado.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        elevation: 0,
        title: Text(
          'Publicar obra musical',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.oroClaro),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Título
            _FieldLabel(label: 'Título *', textMuted: textMuted),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecor(context, isDark, hint: 'Nombre de la obra'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El título es requerido' : null,
            ),
            const SizedBox(height: 18),

            // Tipo de obra
            _FieldLabel(label: 'Tipo de obra', textMuted: textMuted),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _workType,
              decoration: _inputDecor(context, isDark, hint: 'Selecciona el tipo'),
              dropdownColor:
                  isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
              style: TextStyle(color: textPrimary),
              items: _kWorkTypes.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _workType = v),
            ),
            const SizedBox(height: 18),

            // Descripción
            _FieldLabel(label: 'Descripción', textMuted: textMuted),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionCtrl,
              style: TextStyle(color: textPrimary),
              maxLines: 3,
              decoration: _inputDecor(context, isDark,
                  hint: 'Cuéntanos sobre esta obra...'),
            ),
            const SizedBox(height: 18),

            // Enlace YouTube
            _FieldLabel(label: 'Enlace de YouTube', textMuted: textMuted),
            const SizedBox(height: 6),
            TextFormField(
              controller: _youtubeCtrl,
              style: TextStyle(color: textPrimary),
              keyboardType: TextInputType.url,
              decoration: _inputDecor(context, isDark,
                  hint: 'https://www.youtube.com/watch?v=...'),
            ),
            const SizedBox(height: 18),

            // SoundCloud
            _FieldLabel(label: 'Embed de SoundCloud', textMuted: textMuted),
            const SizedBox(height: 6),
            TextFormField(
              controller: _soundcloudCtrl,
              style: TextStyle(color: textPrimary),
              keyboardType: TextInputType.url,
              decoration: _inputDecor(context, isDark,
                  hint: 'https://soundcloud.com/...'),
            ),
            const SizedBox(height: 18),

            // Spotify
            _FieldLabel(label: 'Enlace de Spotify', textMuted: textMuted),
            const SizedBox(height: 6),
            TextFormField(
              controller: _spotifyCtrl,
              style: TextStyle(color: textPrimary),
              keyboardType: TextInputType.url,
              decoration: _inputDecor(context, isDark,
                  hint: 'https://open.spotify.com/track/...'),
            ),
            const SizedBox(height: 18),

            // Fecha de lanzamiento
            _FieldLabel(label: 'Fecha de lanzamiento', textMuted: textMuted),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  style: TextStyle(color: textPrimary),
                  decoration: _inputDecor(context, isDark,
                    hint: 'Selecciona una fecha',
                  ).copyWith(
                    suffixIcon: Icon(Icons.calendar_today_outlined,
                        color: textMuted, size: 18),
                  ),
                  controller: TextEditingController(
                    text: _releaseDate == null
                        ? ''
                        : '${_releaseDate!.day.toString().padLeft(2, '0')}/'
                            '${_releaseDate!.month.toString().padLeft(2, '0')}/'
                            '${_releaseDate!.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Duración
            _FieldLabel(label: 'Duración (segundos)', textMuted: textMuted),
            const SizedBox(height: 6),
            TextFormField(
              controller: _durationCtrl,
              style: TextStyle(color: textPrimary),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  _inputDecor(context, isDark, hint: 'Ej: 210 (3 min 30 s)'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _error!,
                  style: AppTypography.caption(color: AppColors.error),
                ),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tierraProfunda,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Publicar obra',
                        style:
                            AppTypography.labelSemiBold(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(BuildContext context, bool isDark,
      {required String hint}) {
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fill = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          fontSize: 14),
      filled: true,
      fillColor: fill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.tierraProfunda, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.textMuted});
  final String label;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTypography.labelSemiBold(color: textMuted)
            .copyWith(fontSize: 13));
  }
}
