import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../ai/data/ai_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';
import 'publish_artwork_screen/ai_button.dart';
import 'publish_artwork_screen/categoria_dropdown.dart';
import 'publish_artwork_screen/descripcion_field.dart';
import 'publish_artwork_screen/dimensiones_row.dart';
import 'publish_artwork_screen/image_section.dart';
import 'publish_artwork_screen/precio_field.dart';
import 'publish_artwork_screen/sold_warning.dart';
import 'publish_artwork_screen/submit_button.dart';
import 'publish_artwork_screen/tecnica_dropdown.dart';
import 'publish_artwork_screen/titulo_field.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class PublishArtworkScreen extends ConsumerStatefulWidget {
  const PublishArtworkScreen({super.key, this.artworkIdToEdit});

  final String? artworkIdToEdit;

  @override
  ConsumerState<PublishArtworkScreen> createState() =>
      _PublishArtworkScreenState();
}

class _PublishArtworkScreenState extends ConsumerState<PublishArtworkScreen> {
  final _aiService = AiService();

  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dimensionesCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  // Categoria: ID entero que se envía al backend; el nombre se muestra en el dropdown
  int? _categoriaId;
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
      _tituloCtrl.text.trim().isNotEmpty && _categoriaId != null;

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
      // obra.categoria almacena el ID entero como string (viene del JSON del back)
      _categoriaId = int.tryParse(obra.categoria);
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
      final categoria = await _aiService.suggestCategory(titulo);
      if (!mounted) return;
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
    if (titulo.isEmpty || _categoriaId == null) return;

    if (_descCtrl.text.trim().isNotEmpty) {
      final replace = await _confirmReplace();
      if (replace != true) return;
    }

    setState(() => _generateDescLoading = true);
    try {
      final descripcion = await _aiService.generateDescription(
        titulo: titulo,
        categoriaId: _categoriaId!,
      );
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
    if (_categoriaId == null) {
      _showSnackBar('Selecciona una categoría');
      return;
    }
    if (!_modoEdicion && _imagenesSeleccionadas.isEmpty) {
      _showSnackBar('Selecciona al menos una imagen de la obra');
      return;
    }

    setState(() => _isLoading = true);

    // Precio: requerido por el back (DecimalField sin null/blank/default).
    // Se envía 0 si el usuario no especificó precio (obra para exhibición).
    final precio = double.tryParse(_precioCtrl.text.trim()) ?? 0.0;

    final formData = FormData.fromMap({
      'title': _tituloCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': precio,
      'category': _categoriaId,
      if (_tecnica?.trim().isNotEmpty == true) 'technique': _tecnica!.trim(),
      if (_dimensionesCtrl.text.trim().isNotEmpty)
        'dimensions': _dimensionesCtrl.text.trim(),
      if (_imagenesSeleccionadas.isNotEmpty)
        'main_image': await MultipartFile.fromFile(
          _imagenesSeleccionadas.first.path,
          filename: _imagenesSeleccionadas.first.name,
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
      context.go('/artworks/${result.id}', extra: result);
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
      builder: (dialogCtx) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? const [];

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
              if (_isVendida) const SoldWarning(),
              ImageSection(
                imagenes: _imagenesSeleccionadas,
                modoEdicion: _modoEdicion,
                onTap: _seleccionarImagen,
              ),
              const SizedBox(height: 20),
              TituloField(
                controller: _tituloCtrl,
                onChanged: (_) => setState(() {}),
              ),
              if (_canSuggestCategory || _suggestCategoryLoading) ...[
                const SizedBox(height: 10),
                AiButton(
                  label: '✨ Sugerir categoría con IA',
                  isLoading: _suggestCategoryLoading,
                  isDisabled: _isLoading || _suggestCategoryLoading,
                  onPressed: _sugerirCategoriaConIA,
                ),
              ],
              const SizedBox(height: 14),
              CategoriaDropdown(
                categories: categories,
                value: _categoriaId,
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
              const SizedBox(height: 14),
              TecnicaDropdown(
                value: _tecnica,
                onChanged: (v) => setState(() => _tecnica = v),
              ),
              const SizedBox(height: 14),
              DescripcionField(
                controller: _descCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              AiButton(
                label: '✨ Generar descripción con IA',
                isLoading: _generateDescLoading,
                isDisabled:
                    _isLoading || _generateDescLoading || !_canGenerateDesc,
                onPressed: _generarDescripcionConIA,
              ),
              const SizedBox(height: 14),
              DimensionesRow(controller: _dimensionesCtrl),
              const SizedBox(height: 14),
              PrecioField(controller: _precioCtrl),
              const SizedBox(height: 28),
              SubmitButton(
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
