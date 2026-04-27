import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';

class PublishArtworkScreen extends ConsumerStatefulWidget {
  const PublishArtworkScreen({super.key, this.artworkId});

  final int? artworkId;

  @override
  ConsumerState<PublishArtworkScreen> createState() =>
      _PublishArtworkScreenState();
}

class _PublishArtworkScreenState extends ConsumerState<PublishArtworkScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _dimensionesCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  String? _categoria;
  String? _tecnica;

  bool _loading = false;
  String? _error;

  final List<XFile> _pickedImages = [];
  List<String> _existingImages = const [];

  bool get _isEdit => widget.artworkId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      Future.microtask(_loadForEdit);
    }
  }

  Future<void> _loadForEdit() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(artworkRepositoryProvider);
      final artwork = await repo.getDetail(widget.artworkId!);

      _tituloCtrl.text = artwork.titulo;
      _descripcionCtrl.text = artwork.descripcion;
      _dimensionesCtrl.text = artwork.dimensiones ?? '';
      _anioCtrl.text = artwork.anio?.toString() ?? '';
      _precioCtrl.text = artwork.precio?.toString() ?? '';
      _categoria = artwork.categoria;
      _tecnica = artwork.tecnica;
      _existingImages = artwork.imagenes;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _dimensionesCtrl.dispose();
    _anioCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Editar obra' : 'Publicar obra';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          title,
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Datos'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _tituloCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Título *'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un título.'
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('categoria-$_categoria'),
                  initialValue: _categoria,
                  items: [
                    for (final c in kCategoriasNarino)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged:
                      _loading ? null : (v) => setState(() => _categoria = v),
                  decoration: const InputDecoration(labelText: 'Categoría *'),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Selecciona una categoría.'
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('tecnica-${_tecnica ?? ''}'),
                  initialValue: _tecnica ?? '',
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('Sin técnica')),
                    for (final t in kTecnicasNarino)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _tecnica = (v == '' ? null : v)),
                  decoration:
                      const InputDecoration(labelText: 'Técnica (opcional)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dimensionesCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                      labelText: 'Dimensiones (opcional)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _anioCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Año (opcional)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precioCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Precio (opcional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descripcionCtrl,
                  enabled: !_loading,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 18),
                _sectionTitle('Imágenes *'),
                const SizedBox(height: 10),
                _ImagePickerRow(
                  enabled: !_loading,
                  picked: _pickedImages,
                  existing: _existingImages,
                  onPick: _pickImages,
                  onRemovePicked: (i) =>
                      setState(() => _pickedImages.removeAt(i)),
                ),
                if (!_isEdit && _pickedImages.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Debes seleccionar al menos una imagen para publicar.',
                    style: AppTypography.bodySmall(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.oroAndino,
                      foregroundColor: AppColors.obsidiana,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'Guardar cambios' : 'Publicar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.labelSemiBold(color: AppColors.textPrimaryLight),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    setState(() => _pickedImages.addAll(images));
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (!_isEdit && _pickedImages.isEmpty) {
      setState(() => _error = 'Selecciona al menos una imagen.');
      return;
    }

    setState(() => _loading = true);
    try {
      final formData = await _buildFormData();
      final notifier = ref.read(artworkProvider.notifier);

      final result = _isEdit
          ? await notifier.updateArtwork(widget.artworkId!, formData)
          : await notifier.publishArtwork(formData);

      if (!mounted) return;

      if (result == null) {
        setState(() => _error = 'No se pudo guardar la obra.');
        return;
      }

      context.pop();
      context.push('/artworks/${result.id}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<FormData> _buildFormData() async {
    final map = <String, dynamic>{
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'categoria': _categoria,
    };

    final tecnica = _tecnica?.trim();
    if (tecnica != null && tecnica.isNotEmpty) map['tecnica'] = tecnica;

    final dimensiones = _dimensionesCtrl.text.trim();
    if (dimensiones.isNotEmpty) map['dimensiones'] = dimensiones;

    final anio = int.tryParse(_anioCtrl.text.trim());
    if (anio != null) map['anio'] = anio;

    final precio = double.tryParse(_precioCtrl.text.trim());
    if (precio != null) map['precio'] = precio;

    final formData = FormData.fromMap(map);
    for (final file in _pickedImages) {
      formData.files.add(
        MapEntry(
          'imagenes',
          await MultipartFile.fromFile(
            file.path,
            filename: file.name,
          ),
        ),
      );
    }

    return formData;
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:
                  AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerRow extends StatelessWidget {
  const _ImagePickerRow({
    required this.enabled,
    required this.picked,
    required this.existing,
    required this.onPick,
    required this.onRemovePicked,
  });

  final bool enabled;
  final List<XFile> picked;
  final List<String> existing;
  final VoidCallback onPick;
  final void Function(int index) onRemovePicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final url in existing)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 86,
                  height: 86,
                  color: AppColors.bgSubtleLight,
                  child: Image.network(url, fit: BoxFit.cover),
                ),
              ),
            for (var i = 0; i < picked.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 86,
                      height: 86,
                      color: AppColors.bgSubtleLight,
                      child: Image.file(
                        File(picked[i].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: enabled ? () => onRemovePicked(i) : null,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            InkWell(
              onTap: enabled ? onPick : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(Icons.add_a_photo_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
