import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../ai/data/ai_service.dart';
import '../../domain/artwork_model.dart';
import '../providers/artwork_provider.dart';
import '../../../../shared/widgets/dialogs/confirmar_accion.dart';
import '../../../../shared/widgets/dialogs/elegir_origen_foto.dart';
import 'publish_artwork_screen/obra_clasificacion_section.dart';
import 'publish_artwork_screen/obra_datos_section.dart';
import 'publish_artwork_screen/obra_precio_section.dart';
import 'publish_artwork_screen/portada_obra.dart';
import 'publish_artwork_screen/publicar_obra_bottom_bar.dart';

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

  Future<void> _opcionesImagen() async {
    final origen = await elegirOrigenFoto(context);
    if (origen != null) await _elegirImagen(origen);
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
        'main_image': await MultipartFile.fromFile(_imagen!.path,
            filename: _imagen!.name),
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
          : (_modoEdicion
              ? 'Cambios guardados'
              : '¡Tu obra ya está publicada!'));
      context.go('/artworks/${result.id}', extra: result);
    } else {
      final error = ref.read(artworkProvider).errorMessage;
      if (error != null) _snack(error);
    }
  }

  Future<void> _confirmarEliminar() async {
    final ok = await confirmarAccion(
      context,
      titulo: '¿Eliminar esta obra?',
      mensaje: 'Dejará de aparecer en el catálogo. Esta acción no se puede '
          'deshacer.',
      confirmar: 'Eliminar',
      peligro: true,
    );
    if (!ok || !mounted) return;
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
                  NcFormSection(
                    title: 'Imagen de portada',
                    hint: 'Una foto nítida, con buena luz y sin marcos. Es lo '
                        'primero que verá el público.',
                    children: [
                      PortadaObra(
                        archivo: _imagen,
                        urlActual: _obraOriginal?.imagenes.isNotEmpty == true
                            ? _obraOriginal!.imagenes.first
                            : null,
                        error: _intentado && !_modoEdicion && _imagen == null,
                        onTap: _isVendida ? null : _opcionesImagen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ObraDatosSection(
                    titulo: _tituloCtrl,
                    descripcion: _descCtrl,
                    editable: !_isVendida,
                    iaDisponible: _kIaDisponible,
                    generando: _generateDescLoading,
                    onGenerar: _generarDescripcionConIA,
                  ),
                  const SizedBox(height: 16),
                  ObraClasificacionSection(
                    categorias: categorias,
                    categoriaId: _categoriaId,
                    tecnica: _tecnica,
                    dimensiones: _dimensionesCtrl,
                    editable: !_isVendida,
                    mostrarError: _intentado,
                    onCategoria: (id) => setState(() => _categoriaId = id),
                    onTecnica: (t) => setState(() => _tecnica = t),
                  ),
                  const SizedBox(height: 16),
                  ObraPrecioSection(
                    aLaVenta: _aLaVenta,
                    precio: _precioCtrl,
                    editable: !_isVendida,
                    onModo: (v) => setState(() => _aLaVenta = v),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _cargandoObra || _isVendida
          ? null
          : PublicarObraBottomBar(
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
