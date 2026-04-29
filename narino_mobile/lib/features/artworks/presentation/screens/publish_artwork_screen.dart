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
  const PublishArtworkScreen({super.key, this.artworkIdToEdit});

  final int? artworkIdToEdit;

  @override
  ConsumerState<PublishArtworkScreen> createState() =>
      _PublishArtworkScreenState();
}

class _PublishArtworkScreenState extends ConsumerState<PublishArtworkScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dimensionesCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();

  String? _categoria;
  String? _tecnica;

  List<XFile> _imagenesSeleccionadas = [];
  bool _isLoading = false;
  bool _modoEdicion = false;
  ArtworkModel? _obraOriginal;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _modoEdicion = widget.artworkIdToEdit != null;
    if (_modoEdicion) _cargarObra();
  }

  Future<void> _cargarObra() async {
    final obra = await ref
        .read(artworkRepositoryProvider)
        .getDetail(widget.artworkIdToEdit!);
    setState(() {
      _obraOriginal = obra;
      _tituloCtrl.text = obra.titulo;
      _descCtrl.text = obra.descripcion;
      _dimensionesCtrl.text = obra.dimensiones ?? '';
      _precioCtrl.text = obra.precio?.toStringAsFixed(0) ?? '';
      _anioCtrl.text = obra.anio?.toString() ?? '';
      _categoria = obra.categoria;
      _tecnica = obra.tecnica;
    });
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _dimensionesCtrl.dispose();
    _precioCtrl.dispose();
    _anioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          _modoEdicion ? 'Editar obra' : 'Publicar obra',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          if (_modoEdicion &&
              _obraOriginal?.estado != 'vendida' &&
              _obraOriginal?.estado != 'en_subasta')
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Eliminar obra',
              onPressed: _confirmarEliminar,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_modoEdicion && _obraOriginal?.estado == 'vendida')
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMutedLight.withValues(alpha: 20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    'Esta obra ya fue vendida. Solo puedes archivarla.',
                    style: AppTypography.bodySmall(
                        color: AppColors.textMutedLight),
                  ),
                ),
              Text(
                'Imágenes de la obra',
                style: AppTypography.labelSemiBold(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.bgSubtleLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderLight,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imagenesSeleccionadas.isNotEmpty
                      ? ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          itemCount: _imagenesSeleccionadas.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagenesSeleccionadas[i].path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: AppColors.textMutedLight,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _modoEdicion
                                    ? 'Toca para cambiar imágenes'
                                    : 'Toca para seleccionar imágenes *',
                                style: AppTypography.caption(
                                  color: AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tituloCtrl,
                textCapitalization: TextCapitalization.sentences,
                style:
                    AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
                decoration: const InputDecoration(
                  labelText: 'Título de la obra *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El título es obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                hint: Text(
                  'Categoría artística *',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textMutedLight,
                  ),
                ),
                items: kCategoriasNarino
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v),
                validator: (v) => v == null ? 'Selecciona una categoría' : null,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: _tecnica,
                hint: Text(
                  'Técnica (opcional)',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textMutedLight,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin especificar'),
                  ),
                  ...kTecnicasNarino
                      .map((t) => DropdownMenuItem(value: t, child: Text(t))),
                ],
                onChanged: (v) => setState(() => _tecnica = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.brush_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style:
                    AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dimensionesCtrl,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimaryLight,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Dimensiones',
                        hintText: '50x70 cm',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _anioCtrl,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimaryLight,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        hintText: '2024',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          final y = int.tryParse(v);
                          if (y == null ||
                              y < 1900 ||
                              y > DateTime.now().year) {
                            return 'Año inválido';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _precioCtrl,
                keyboardType: TextInputType.number,
                style:
                    AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
                decoration: const InputDecoration(
                  labelText: 'Precio en COP (opcional)',
                  hintText: 'Déjalo vacío si es para exhibición',
                  prefixIcon: Icon(Icons.sell_outlined),
                  prefixText: r'$ ',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading ||
                          (_modoEdicion && _obraOriginal?.estado == 'vendida'))
                      ? null
                      : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _modoEdicion ? 'Guardar cambios' : 'Publicar obra',
                          style: AppTypography.buttonText(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked.isNotEmpty) {
      setState(() => _imagenesSeleccionadas = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    if (!_modoEdicion && _imagenesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una imagen de la obra'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final tecnica = _tecnica?.trim();

    final formData = FormData.fromMap({
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'categoria': _categoria!,
      if (tecnica != null && tecnica.isNotEmpty) 'tecnica': tecnica,
      if (_dimensionesCtrl.text.trim().isNotEmpty)
        'dimensiones': _dimensionesCtrl.text.trim(),
      if (_precioCtrl.text.trim().isNotEmpty)
        'precio': double.tryParse(_precioCtrl.text.trim()),
      if (_anioCtrl.text.trim().isNotEmpty)
        'anio': int.tryParse(_anioCtrl.text),
      if (_imagenesSeleccionadas.isNotEmpty)
        'imagenes': await Future.wait(
          _imagenesSeleccionadas
              .map((f) async => MultipartFile.fromFile(
                    f.path,
                    filename: f.name,
                  ))
              .toList(),
        ),
    });

    final notifier = ref.read(artworkProvider.notifier);
    ArtworkModel? result;

    if (_modoEdicion) {
      result = await notifier.update(widget.artworkIdToEdit!, formData);
    } else {
      result = await notifier.publish(formData);
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion
                ? 'Obra actualizada correctamente'
                : 'Obra publicada exitosamente',
          ),
        ),
      );
      context.go('/artworks/${result.id}');
    } else {
      final error = ref.read(artworkProvider).errorMessage;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  Future<void> _confirmarEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Eliminar obra',
          style:
              AppTypography.displaySemiBold(color: AppColors.textPrimaryLight),
        ),
        content: Text(
          '¿Estás segura de que quieres eliminar esta obra? Esta acción no se puede deshacer.',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      setState(() => _isLoading = true);
      final ok = await ref
          .read(artworkProvider.notifier)
          .deleteArtwork(widget.artworkIdToEdit!);
      setState(() => _isLoading = false);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obra eliminada')),
        );
        context.go('/catalog');
      }
    }
  }
}
