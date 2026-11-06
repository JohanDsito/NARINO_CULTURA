import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../ai/data/ai_service.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';

/// Los endpoints `/ai/suggest-category/` y `/ai/generate-description/` aún no
/// existen en el backend: los botones de IA se ocultan hasta que estén.
const _kIaDisponible = false;

/// Publicar o editar una obra (acento magenta).
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
  final _picker = ImagePicker();

  int? _categoriaId;
  String? _tecnica;
  XFile? _imagen;
  bool _aLaVenta = true;
  ArtworkModel? _obraOriginal;
  bool _isLoading = false;
  bool _cargandoObra = false;
  bool _generateDescLoading = false;
  bool _intentado = false;

  bool get _modoEdicion => widget.artworkIdToEdit != null;
  bool get _isVendida => _obraOriginal?.estado == 'vendida';

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

  // ─── Carga ────────────────────────────────────────────────────────────────

  Future<void> _cargarObra() async {
    setState(() => _cargandoObra = true);
    try {
      final obra = await ref
          .read(artworkRepositoryProvider)
          .getDetail(widget.artworkIdToEdit!);
      if (!mounted) return;
      setState(() {
        _obraOriginal = obra;
        _tituloCtrl.text = obra.titulo;
        _descCtrl.text = obra.descripcion;
        _dimensionesCtrl.text = obra.dimensiones ?? '';
        _aLaVenta = obra.precio != null;
        _precioCtrl.text = obra.precio?.toStringAsFixed(0) ?? '';
        _categoriaId = obra.categoriaId;
        _tecnica = obra.tecnica;
      });
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _cargandoObra = false);
    }
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _elegirImagen(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, maxWidth: 1600, imageQuality: 85);
    if (picked != null) setState(() => _imagen = picked);
  }

  void _opcionesImagen() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _elegirImagen(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _elegirImagen(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generarDescripcionConIA() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty || _categoriaId == null) return;
    setState(() => _generateDescLoading = true);
    try {
      final d = await _aiService.generateDescription(
          titulo: titulo, categoriaId: _categoriaId!);
      if (mounted) setState(() => _descCtrl.text = d);
    } catch (_) {
      if (mounted) _snack('No se pudo generar la descripción con IA.');
    } finally {
      if (mounted) setState(() => _generateDescLoading = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _intentado = true);
    final formOk = _formKey.currentState!.validate();
    final falta = <String>[
      if (_categoriaId == null) 'una categoría',
      if (!_modoEdicion && _imagen == null) 'la imagen de portada',
    ];
    if (!formOk || falta.isNotEmpty) {
      if (falta.isNotEmpty) _snack('Falta ${falta.join(' y ')}.');
      return;
    }

    setState(() => _isLoading = true);
    // El backend exige `price`; 0 = obra solo para exhibición.
    final precio =
        _aLaVenta ? (double.tryParse(_precioCtrl.text.trim()) ?? 0) : 0.0;
    final formData = FormData.fromMap({
      'title': _tituloCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': precio,
      'category': _categoriaId,
      if (_tecnica?.trim().isNotEmpty == true) 'technique': _tecnica!.trim(),
      if (_dimensionesCtrl.text.trim().isNotEmpty)
        'dimensions': _dimensionesCtrl.text.trim(),
      if (_imagen != null)
        'main_image':
            await MultipartFile.fromFile(_imagen!.path, filename: _imagen!.name),
    });

    final notifier = ref.read(artworkProvider.notifier);
    final result = _modoEdicion
        ? await notifier.update(widget.artworkIdToEdit!, formData)
        : await notifier.publish(formData);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      final original = _obraOriginal?.precio;
      final bajoPrecio =
          _modoEdicion && original != null && precio > 0 && precio < original;
      _snack(bajoPrecio
          ? 'Precio actualizado. Quienes la tienen en favoritos recibirán un aviso.'
          : (_modoEdicion ? 'Cambios guardados' : '¡Tu obra ya está publicada!'));
      context.go('/artworks/${result.id}', extra: result);
    } else {
      final error = ref.read(artworkProvider).errorMessage;
      if (error != null) _snack(error);
    }
  }

  Future<void> _confirmarEliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta obra?'),
        content: const Text(
            'Dejará de aparecer en el catálogo. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tomate,
              foregroundColor: Colors.black,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _isLoading = true);
    final deleted = await ref
        .read(artworkProvider.notifier)
        .deleteArtwork(widget.artworkIdToEdit!);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (deleted) {
      _snack('Obra eliminada');
      context.go('/catalog');
    } else {
      _snack('No se pudo eliminar la obra.');
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final categorias =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryModel>[];
    final puedeEliminar = _modoEdicion &&
        !_isVendida &&
        _obraOriginal != null &&
        _obraOriginal!.estado != 'en_subasta';

    Widget titulo(String t, {String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t,
                  style: AppTypography.labelSemiBold(color: nc.textPrimary)),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(hint,
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
              ],
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_modoEdicion ? 'Editar obra' : 'Publicar obra'),
        actions: [
          if (puedeEliminar)
            IconButton(
              tooltip: 'Eliminar obra',
              icon: Icon(Icons.delete_outline_rounded, color: nc.tomateA.ink),
              onPressed: _isLoading ? null : _confirmarEliminar,
            ),
        ],
      ),
      body: _cargandoObra
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  if (_isVendida) ...[
                    NcBanner(
                      accent: nc.oroA,
                      icon: Icons.lock_outline_rounded,
                      message: 'Esta obra ya fue vendida. Puedes consultarla, '
                          'pero no editarla.',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Portada ──
                  NcCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titulo('Imagen de portada',
                            hint: 'Una foto nítida, con buena luz y sin '
                                'marcos. Es lo primero que verá el público.'),
                        _Portada(
                          archivo: _imagen,
                          urlActual: _obraOriginal?.imagenes.isNotEmpty == true
                              ? _obraOriginal!.imagenes.first
                              : null,
                          error: _intentado && !_modoEdicion && _imagen == null,
                          onTap: _isVendida ? null : _opcionesImagen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Datos ──
                  NcCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        titulo('Sobre la obra'),
                        TextFormField(
                          controller: _tituloCtrl,
                          enabled: !_isVendida,
                          maxLength: 120,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            counterText: '',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ponle un título a tu obra'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descCtrl,
                          enabled: !_isVendida,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: 1500,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            alignLabelWithHint: true,
                            hintText: 'Cuenta la historia, la técnica y qué '
                                'la hace especial.',
                          ),
                        ),
                        if (_kIaDisponible)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _generateDescLoading
                                  ? null
                                  : _generarDescripcionConIA,
                              icon: const Icon(Icons.auto_awesome_outlined),
                              label: const Text('Escribir con IA'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Clasificación ──
                  NcCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        titulo('Categoría'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (categorias.isEmpty)
                              Text('Cargando categorías…',
                                  style: AppTypography.bodySmall(
                                      color: nc.textSecondary)),
                            for (final c in categorias)
                              ChoiceChip(
                                label: Text(c.displayName),
                                selected: _categoriaId == c.id,
                                showCheckmark: false,
                                onSelected: _isVendida
                                    ? null
                                    : (_) =>
                                        setState(() => _categoriaId = c.id),
                                selectedColor: nc.catalogo.fill,
                                side: BorderSide(
                                  color: _categoriaId == c.id
                                      ? nc.catalogo.fill
                                      : (_intentado && _categoriaId == null
                                          ? nc.tomateA.fill
                                          : nc.border),
                                ),
                                labelStyle: AppTypography.labelMedium(
                                  color: _categoriaId == c.id
                                      ? nc.catalogo.onFill
                                      : nc.textPrimary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                        if (_intentado && _categoriaId == null) ...[
                          const SizedBox(height: 8),
                          Text('Elige una categoría',
                              style: AppTypography.bodySmall(
                                  color: nc.tomateA.ink)),
                        ],
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String?>(
                          initialValue: _tecnica,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Técnica (opcional)',
                            prefixIcon: Icon(Icons.brush_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('Sin especificar')),
                            for (final t in {
                              ...kTecnicasNarino,
                              if (_tecnica != null) _tecnica!,
                            })
                              DropdownMenuItem(value: t, child: Text(t)),
                          ],
                          onChanged: _isVendida
                              ? null
                              : (v) => setState(() => _tecnica = v),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _dimensionesCtrl,
                          enabled: !_isVendida,
                          decoration: const InputDecoration(
                            labelText: 'Dimensiones (opcional)',
                            hintText: 'Ej.: 50 × 70 cm',
                            prefixIcon: Icon(Icons.straighten_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Precio ──
                  NcCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        titulo('Precio'),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('A la venta'),
                              icon: Icon(Icons.sell_outlined),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Exhibición'),
                              icon: Icon(Icons.visibility_outlined),
                            ),
                          ],
                          selected: {_aLaVenta},
                          showSelectedIcon: false,
                          onSelectionChanged: _isVendida
                              ? null
                              : (s) => setState(() => _aLaVenta = s.first),
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: nc.tienda.fill,
                            selectedForegroundColor: nc.tienda.onFill,
                            side: BorderSide(color: nc.border),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 220),
                          crossFadeState: _aLaVenta
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: TextFormField(
                            controller: _precioCtrl,
                            enabled: !_isVendida,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Precio en pesos',
                              prefixText: r'$ ',
                              suffixText: 'COP',
                            ),
                            validator: (v) {
                              if (!_aLaVenta) return null;
                              final n = double.tryParse(v?.trim() ?? '');
                              if (n == null || n <= 0) {
                                return 'Escribe un precio mayor que 0';
                              }
                              return null;
                            },
                          ),
                          secondChild: Text(
                            'La obra aparecerá en el catálogo sin opción de '
                            'compra. Podrás ponerla a la venta después.',
                            style: AppTypography.bodySmall(
                                color: nc.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _cargandoObra || _isVendida
          ? null
          : _BottomBar(
              child: NcPrimaryButton(
                label: _modoEdicion ? 'Guardar cambios' : 'Publicar obra',
                icon: _modoEdicion
                    ? Icons.check_rounded
                    : Icons.rocket_launch_outlined,
                loading: _isLoading,
                onPressed: _submit,
              ),
            ),
    );
  }
}

class _Portada extends StatelessWidget {
  const _Portada({
    required this.archivo,
    required this.urlActual,
    required this.error,
    required this.onTap,
  });

  final XFile? archivo;
  final String? urlActual;
  final bool error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final tieneImagen = archivo != null || urlActual != null;

    Widget contenido;
    if (archivo != null) {
      contenido = Image.file(File(archivo!.path), fit: BoxFit.cover);
    } else if (urlActual != null) {
      contenido = CachedNetworkImage(imageUrl: urlActual!, fit: BoxFit.cover);
    } else {
      contenido = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NcAccentIcon(
            icon: Icons.add_photo_alternate_outlined,
            accent: error ? nc.tomateA : nc.catalogo,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text('Toca para agregar la portada',
              style: AppTypography.labelSemiBold(
                  color: error ? nc.tomateA.ink : nc.textPrimary)),
          const SizedBox(height: 2),
          Text('JPG o PNG · se ajusta automáticamente',
              style: AppTypography.bodySmall(color: nc.textSecondary)),
        ],
      );
    }

    return Semantics(
      button: true,
      label: tieneImagen ? 'Cambiar imagen de portada' : 'Agregar imagen de portada',
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: tieneImagen ? Colors.black : nc.catalogo.tint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: error
                    ? nc.tomateA.fill
                    : (tieneImagen
                        ? nc.border
                        : nc.catalogo.fill.withValues(alpha: 0.5)),
                width: error ? 1.6 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                contenido,
                if (tieneImagen && onTap != null)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color: Colors.black.withValues(alpha: 0.4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('Cambiar',
                                  style: AppTypography.labelMedium(
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: nc.bgGlass,
            border: Border(top: BorderSide(color: nc.border)),
          ),
          child: child,
        ),
      ),
    );
  }
}
