import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/profile_model.dart';
import '../../domain/profile_state.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  final _ttCtrl = TextEditingController();

  String? _disciplina;
  File? _nuevaFoto;
  bool _initialized = false;
  bool _showPreview = false;

  final _picker = ImagePicker();

  void _initFrom(ProfileModel p) {
    if (_initialized) return;
    _nombreCtrl.text = p.nombreArtistico;
    _bioCtrl.text = p.biografia ?? '';
    _igCtrl.text = p.redesSociales['instagram'] ?? '';
    _fbCtrl.text = p.redesSociales['facebook'] ?? '';
    _ttCtrl.text = p.redesSociales['tiktok'] ?? '';
    _disciplina = p.disciplina;
    _initialized = true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _bioCtrl.dispose();
    _igCtrl.dispose();
    _fbCtrl.dispose();
    _ttCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked != null) setState(() => _nuevaFoto = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final redesSociales = <String, String>{};
    if (_igCtrl.text.trim().isNotEmpty) {
      redesSociales['instagram'] = _igCtrl.text.trim();
    }
    if (_fbCtrl.text.trim().isNotEmpty) {
      redesSociales['facebook'] = _fbCtrl.text.trim();
    }
    if (_ttCtrl.text.trim().isNotEmpty) {
      redesSociales['tiktok'] = _ttCtrl.text.trim();
    }

    final ok = await ref.read(myProfileProvider.notifier).updateProfile(
          nombreArtistico: _nombreCtrl.text.trim(),
          disciplina: _disciplina!,
          biografia: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          foto: _nuevaFoto,
          redesSociales: redesSociales,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Perfil actualizado'),
          backgroundColor: AppColors.selvaAndina));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProfileProvider);
    if (state.profile != null) _initFrom(state.profile!);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
          // HU-11: Vista previa antes de guardar
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

  Widget _buildPreview(profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.tierraPalida,
                  backgroundImage: _nuevaFoto != null
                      ? FileImage(_nuevaFoto!) as ImageProvider
                      : (profile?.fotoUrl != null
                          ? NetworkImage(profile!.fotoUrl!)
                          : null),
                  child: (_nuevaFoto == null && profile?.fotoUrl == null)
                      ? Text(
                          _nombreCtrl.text.isNotEmpty
                              ? _nombreCtrl.text[0].toUpperCase()
                              : '?',
                          style: AppTypography.displayBold(
                              color: AppColors.tierraProfunda))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                    _nombreCtrl.text.isEmpty
                        ? 'Nombre artístico'
                        : _nombreCtrl.text,
                    style: AppTypography.displaySemiBold(
                        color: AppColors.textPrimaryLight)),
                Text(_disciplina ?? '',
                    style: AppTypography.quoteItalic(
                        color: AppColors.textMutedLight)),
                if (_bioCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_bioCtrl.text,
                      style: AppTypography.bodyMedium(
                          color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Esta es la vista previa de tu perfil público.',
              style: AppTypography.caption(color: AppColors.textMutedLight),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
                onPressed: _save,
                child: Text('Guardar cambios',
                    style: AppTypography.buttonText(color: Colors.white))),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ProfileState state) {
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
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.tierraPalida,
                      backgroundImage: _nuevaFoto != null
                          ? FileImage(_nuevaFoto!) as ImageProvider
                          : (state.profile?.fotoUrl != null
                              ? NetworkImage(state.profile!.fotoUrl!)
                              : null),
                      child:
                          (_nuevaFoto == null && state.profile?.fotoUrl == null)
                              ? const Icon(Icons.person_outline,
                                  size: 48, color: AppColors.tierraProfunda)
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: AppColors.tierraProfunda,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
                child: Text('JPG/PNG · máx. 5 MB',
                    style: AppTypography.caption(
                        color: AppColors.textMutedLight))),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nombreCtrl,
              style:
                  AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
              decoration: const InputDecoration(
                  labelText: 'Nombre artístico *',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre artístico es obligatorio'
                  : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _disciplina,
              decoration: const InputDecoration(
                  labelText: 'Disciplina *',
                  prefixIcon: Icon(Icons.brush_outlined)),
              style:
                  AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
              items: ArtisticDisciplines.all
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _disciplina = v),
              validator: (v) => v == null ? 'Selecciona una disciplina' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _bioCtrl,
              maxLines: 5,
              maxLength: 500,
              style:
                  AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
              decoration: const InputDecoration(
                  labelText: 'Biografía (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 4),

            // Redes sociales (HU-10: hasta 3)
            Text('Redes sociales',
                style: AppTypography.labelSemiBold(
                    color: AppColors.textSecondaryLight)),
            const SizedBox(height: 10),
            TextFormField(
                controller: _igCtrl,
                style:
                    AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
                decoration: const InputDecoration(
                    labelText: 'Instagram (URL)',
                    prefixIcon: Icon(Icons.link))),
            const SizedBox(height: 10),
            TextFormField(
                controller: _fbCtrl,
                style:
                    AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
                decoration: const InputDecoration(
                    labelText: 'Facebook (URL)', prefixIcon: Icon(Icons.link))),
            const SizedBox(height: 10),
            TextFormField(
                controller: _ttCtrl,
                style:
                    AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
                decoration: const InputDecoration(
                    labelText: 'TikTok (URL)', prefixIcon: Icon(Icons.link))),
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Guardar cambios',
                        style: AppTypography.buttonText(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
