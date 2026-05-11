import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';

// ─── Constantes ──────────────────────────────────────────────────────────────

const _kFieldPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

// ─── Pantalla principal ───────────────────────────────────────────────────────

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
  ArtworkModel? _obraOriginal;

  bool _isLoading = false;
  bool _suggestCategoryLoading = false;
  bool _generateDescLoading = false;

  bool get _modoEdicion => widget.artworkIdToEdit != null;
  bool get _isVendida => _obraOriginal?.estado == 'vendida';
  bool get _canSuggestCategory =>
      _imagenesSeleccionadas.isNotEmpty && _tituloCtrl.text.trim().isNotEmpty;
  bool get _canGenerateDesc =>
      _tituloCtrl.text.trim().isNotEmpty &&
      (_categoria?.trim().isNotEmpty == true);

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (_modoEdicion) _cargarObra();
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

  // ─── Carga de datos ──────────────────────────────────────────────────────────

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

  // ─── Acciones ────────────────────────────────────────────────────────────────

  Future<void> _seleccionarImagen() async {
    final picked =
        await _picker.pickMultiImage(maxWidth: 1080, imageQuality: 85);
    if (picked.isNotEmpty) setState(() => _imagenesSeleccionadas = picked);
  }

  Future<void> _sugerirCategoriaConIA() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty || _imagenesSeleccionadas.isEmpty) return;

    setState(() => _suggestCategoryLoading = true);
    try {
      final response = await ApiClient.instance.dio.post(
        '/ai/suggest-category/',
        data: {'titulo': titulo},
      );
      final data = response.data;
      final categoria = (data is Map ? data['categoria'] : null)?.toString();
      if (categoria == null || categoria.isEmpty) throw Exception('Vacío');
      if (!mounted) return;
      setState(() => _categoria = categoria);
      _showSnackBar(
          'Categoría sugerida: $categoria. Puedes cambiarla si prefieres.');
    } catch (_) {
      if (mounted) {
        _showSnackBar(
            'No se pudo sugerir una categoría. Selecciónala manualmente.');
      }
    } finally {
      if (mounted) setState(() => _suggestCategoryLoading = false);
    }
  }

  Future<void> _generarDescripcionConIA() async {
    final titulo = _tituloCtrl.text.trim();
    final categoria = _categoria?.trim() ?? '';
    if (titulo.isEmpty || categoria.isEmpty) return;

    if (_descCtrl.text.trim().isNotEmpty) {
      final replace = await _confirmReplace();
      if (replace != true) return;
    }

    setState(() => _generateDescLoading = true);
    try {
      final response = await ApiClient.instance.dio.post(
        '/ai/generate-description/',
        data: {'titulo': titulo, 'categoria': categoria},
      );
      final data = response.data;
      final descripcion =
          (data is Map ? data['descripcion'] : null)?.toString();
      if (descripcion == null || descripcion.isEmpty) throw Exception('Vacío');
      if (!mounted) return;
      setState(() => _descCtrl.text = descripcion);
    } catch (_) {
      if (mounted) {
        _showSnackBar('No se pudo generar la descripción con IA.');
      }
    } finally {
      if (mounted) setState(() => _generateDescLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoria == null) {
      _showSnackBar('Selecciona una categoría');
      return;
    }
    if (!_modoEdicion && _imagenesSeleccionadas.isEmpty) {
      _showSnackBar('Selecciona al menos una imagen de la obra');
      return;
    }

    setState(() => _isLoading = true);

    final formData = FormData.fromMap({
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'categoria': _categoria!,
      if (_tecnica?.trim().isNotEmpty == true) 'tecnica': _tecnica!.trim(),
      if (_dimensionesCtrl.text.trim().isNotEmpty)
        'dimensiones': _dimensionesCtrl.text.trim(),
      if (_precioCtrl.text.trim().isNotEmpty)
        'precio': double.tryParse(_precioCtrl.text.trim()),
      if (_anioCtrl.text.trim().isNotEmpty)
        'anio': int.tryParse(_anioCtrl.text),
      if (_imagenesSeleccionadas.isNotEmpty)
        'imagenes': await Future.wait(
          _imagenesSeleccionadas
              .map(
                  (f) async => MultipartFile.fromFile(f.path, filename: f.name))
              .toList(),
        ),
    });

    final notifier = ref.read(artworkProvider.notifier);
    final result = _modoEdicion
        ? await notifier.update(widget.artworkIdToEdit!, formData)
        : await notifier.publish(formData);

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      final precioBajo = _checkPrecioBajo(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: precioBajo ? AppColors.selvaAndina : null,
          content: Text(
            precioBajo
                ? '✅ Precio actualizado. Los usuarios con esta obra en favoritos serán notificados.'
                : (_modoEdicion
                    ? 'Obra actualizada correctamente'
                    : 'Obra publicada exitosamente'),
            style: precioBajo
                ? AppTypography.bodyMedium(color: Colors.white)
                : null,
          ),
        ),
      );
      context.go('/artworks/${result.id}');
    } else {
      final error = ref.read(artworkProvider).errorMessage;
      if (error != null && mounted) _showSnackBar(error);
    }
  }

  Future<void> _confirmarEliminar() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        // ✅ FIX: color del AlertDialog resuelto desde el tema
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Text(
          'Eliminar obra',
          style: AppTypography.displaySemiBold(color: textPrimary),
        ),
        content: Text(
          '¿Estás segura de que quieres eliminar esta obra? '
          'Esta acción no se puede deshacer.',
          style: AppTypography.bodyMedium(color: textSecondary),
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
        _showSnackBar('Obra eliminada');
        context.go('/catalog');
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool _checkPrecioBajo(ArtworkModel result) {
    final originalPrecio = _obraOriginal?.precio;
    final nuevoPrecio = _precioCtrl.text.trim().isNotEmpty
        ? double.tryParse(_precioCtrl.text.trim())
        : null;
    return _modoEdicion &&
        originalPrecio != null &&
        nuevoPrecio != null &&
        nuevoPrecio < originalPrecio;
  }

  Future<bool?> _confirmReplace() => showDialog<bool>(
        context: context,
        builder: (context) {
          // ✅ FIX: color del AlertDialog resuelto desde el tema
          final theme = Theme.of(context);
          return AlertDialog(
            backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            title: const Text('Reemplazar descripción'),
            content: const Text(
                '¿Reemplazar la descripción actual con la generada por IA?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reemplazar'),
              ),
            ],
          );
        },
      );

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          _modoEdicion ? 'Editar obra' : 'Publicar obra',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        actions: [
          if (_modoEdicion &&
              !_isVendida &&
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
              if (_isVendida) const _SoldWarning(),
              _ImageSection(
                imagenes: _imagenesSeleccionadas,
                modoEdicion: _modoEdicion,
                onTap: _seleccionarImagen,
              ),
              const SizedBox(height: 20),
              _TituloField(
                controller: _tituloCtrl,
                onChanged: (_) => setState(() {}),
              ),
              if (_canSuggestCategory || _suggestCategoryLoading) ...[
                const SizedBox(height: 10),
                _AiButton(
                  label: '✨ Sugerir categoría con IA',
                  isLoading: _suggestCategoryLoading,
                  isDisabled: _isLoading || _suggestCategoryLoading,
                  onPressed: _sugerirCategoriaConIA,
                ),
              ],
              const SizedBox(height: 14),
              _CategoriaDropdown(
                value: _categoria,
                onChanged: (v) => setState(() => _categoria = v),
              ),
              const SizedBox(height: 14),
              _TecnicaDropdown(
                value: _tecnica,
                onChanged: (v) => setState(() => _tecnica = v),
              ),
              const SizedBox(height: 14),
              _DescripcionField(
                controller: _descCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _AiButton(
                label: '✨ Generar descripción con IA',
                isLoading: _generateDescLoading,
                isDisabled:
                    _isLoading || _generateDescLoading || !_canGenerateDesc,
                onPressed: _generarDescripcionConIA,
              ),
              const SizedBox(height: 14),
              _DimensionesAnioRow(
                dimensionesCtrl: _dimensionesCtrl,
                anioCtrl: _anioCtrl,
              ),
              const SizedBox(height: 14),
              _PrecioField(controller: _precioCtrl),
              const SizedBox(height: 28),
              _SubmitButton(
                modoEdicion: _modoEdicion,
                isLoading: _isLoading,
                isDisabled: _isLoading || _isVendida,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets de sección ───────────────────────────────────────────────────────

class _SoldWarning extends StatelessWidget {
  const _SoldWarning();

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: colores hardcodeados → resueltos desde el tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = textMuted.withValues(alpha: 0.08);

    return Container(
      padding: _kFieldPadding, // ✅ USO de _kFieldPadding
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta obra ya fue vendida. Solo puedes archivarla.',
              style: AppTypography.bodySmall(color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imagenes,
    required this.modoEdicion,
    required this.onTap,
  });

  final List<XFile> imagenes;
  final bool modoEdicion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: colores hardcodeados → resueltos desde el tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imágenes de la obra',
          style: AppTypography.labelSemiBold(color: textSecondary),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: bgSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: imagenes.isNotEmpty
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: imagenes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagenes[i].path),
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
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: textMuted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          modoEdicion
                              ? 'Toca para cambiar imágenes'
                              : 'Toca para seleccionar imágenes *',
                          style: AppTypography.caption(color: textMuted),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Campos del formulario ────────────────────────────────────────────────────

class _TituloField extends StatelessWidget {
  const _TituloField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: color del texto resuelto desde el tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      style: AppTypography.bodyMedium(color: textPrimary),
      decoration: const InputDecoration(
        labelText: 'Título de la obra *',
        prefixIcon: Icon(Icons.title),
        contentPadding: _kFieldPadding, // ✅ USO de _kFieldPadding
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
      onChanged: onChanged,
    );
  }
}

class _CategoriaDropdown extends StatelessWidget {
  const _CategoriaDropdown({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: colores resueltos desde el tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return DropdownButtonFormField<String>(
      initialValue: value,
      style: AppTypography.bodyMedium(color: textPrimary),
      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      hint: Text(
        'Categoría artística *',
        style: AppTypography.bodyMedium(color: textMuted),
      ),
      items: kCategoriasNarino
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una categoría' : null,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.category_outlined),
        contentPadding: _kFieldPadding, // ✅ USO de _kFieldPadding
      ),
    );
  }
}

class _TecnicaDropdown extends StatelessWidget {
  const _TecnicaDropdown({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: colores resueltos desde el tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return DropdownButtonFormField<String?>(
      initialValue: value,
      style: AppTypography.bodyMedium(color: textPrimary),
      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      hint: Text(
        'Técnica (opcional)',
        style: AppTypography.bodyMedium(color: textMuted),
      ),
      items: [
        const DropdownMenuItem<String?>(
            value: null, child: Text('Sin especificar')),
        ...kTecnicasNarino
            .map((t) => DropdownMenuItem(value: t, child: Text(t))),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.brush_outlined),
        contentPadding: _kFieldPadding, // ✅ USO de _kFieldPadding
      ),
    );
  }
}

class _DescripcionField extends StatelessWidget {
  const _DescripcionField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: color del texto resuelto desde el tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return TextFormField(
      controller: controller,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      style: AppTypography.bodyMedium(color: textPrimary),
      decoration: const InputDecoration(
        labelText: 'Descripción',
        alignLabelWithHint: true,
        contentPadding: _kFieldPadding, // ✅ USO de _kFieldPadding
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 56),
          child: Icon(Icons.description_outlined),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _DimensionesAnioRow extends StatelessWidget {
  const _DimensionesAnioRow({
    required this.dimensionesCtrl,
    required this.anioCtrl,
  });

  final TextEditingController dimensionesCtrl;
  final TextEditingController anioCtrl;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: color del texto resuelto desde el tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: dimensionesCtrl,
            style: AppTypography.bodyMedium(color: textPrimary),
            decoration: const InputDecoration(
              labelText: 'Dimensiones',
              hintText: '50x70 cm',
              prefixIcon: Icon(Icons.straighten_outlined),
              contentPadding: _kFieldPadding, // ✅ USO de _kFieldPadding
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: anioCtrl,
            keyboardType: TextInputType.number,
            style: AppTypography.bodyMedium(color: textPrimary),
            decoration: const InputDecoration(
              labelText: 'Año',
              hintText: '2024',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              contentPadding: _kFieldPadding, // ✅ USO de _kFieldPadding
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                final y = int.tryParse(v);
                if (y == null || y < 1900 || y > DateTime.now().year) {
                  return 'Año inválido';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _PrecioField extends StatelessWidget {
  const _PrecioField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: color del texto resuelto desde el tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppTypography.bodyMedium(color: textPrimary),
      decoration: const InputDecoration(
        labelText: 'Precio en COP (opcional)',
        hintText: 'Déjalo vacío si es para exhibición',
        prefixIcon: Icon(Icons.sell_outlined),
        prefixText: r'$ ',
        contentPadding: _kFieldPadding, // ✅ USO de _kFieldPadding
      ),
    );
  }
}

// ─── Botón IA ─────────────────────────────────────────────────────────────────

class _AiButton extends StatelessWidget {
  const _AiButton({
    required this.label,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: colores del botón IA resueltos desde el tema para que se adapten
    // al modo oscuro. En dark se usa tierraDark; en light, tierraProfunda.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiColor = isDark ? AppColors.tierraDark : AppColors.tierraProfunda;

    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: aiColor,
          side: BorderSide(color: aiColor, width: 1.5),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: aiColor,
                ),
              )
            : Text(
                label,
                style: AppTypography.labelSemiBold(color: aiColor),
              ),
      ),
    );
  }
}

// ─── Botón de envío ───────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.modoEdicion,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final bool modoEdicion;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        // ✅ FIX: color del botón de envío resuelto desde el tema
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: cs.onPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                modoEdicion ? 'Guardar cambios' : 'Publicar obra',
                style: AppTypography.buttonText(color: cs.onPrimary),
              ),
      ),
    );
  }
}
