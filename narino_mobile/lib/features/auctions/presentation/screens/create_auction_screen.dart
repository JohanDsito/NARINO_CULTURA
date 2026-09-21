import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../providers/auctions_provider.dart';
import 'create_auction_screen/artworks_empty.dart';
import 'create_auction_screen/artworks_error.dart';
import 'create_auction_screen/artworks_loading.dart';
import 'create_auction_screen/date_time_picker.dart';
import 'create_auction_screen/duracion_slider.dart';
import 'create_auction_screen/error_banner.dart';
import 'create_auction_screen/section_label.dart';
import 'create_auction_screen/submit_button.dart';

// ─── Pantalla principal ───────────────────────────────────────────────────────

class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() =>
      _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precioBaseCtrl = TextEditingController();

  ArtworkModel? _selectedArtwork;
  int _duracionDias = 7;
  DateTime? _fecha;
  TimeOfDay? _hora;

  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  void dispose() {
    _precioBaseCtrl.dispose();
    super.dispose();
  }

  // ─── Fecha y hora ─────────────────────────────────────────────────────────

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: ThemeData(
          colorScheme: isDark
              ? const ColorScheme.dark(primary: AppColors.tierraDark)
              : const ColorScheme.light(primary: AppColors.tierraProfunda),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    setState(() {
      _fecha = date;
      _hora = time;
    });
  }

  DateTime? get _fechaInicio {
    if (_fecha == null) return null;
    final h = _hora?.hour ?? 0;
    final m = _hora?.minute ?? 0;
    return DateTime(_fecha!.year, _fecha!.month, _fecha!.day, h, m);
  }

  String get _fechaLabel {
    final fi = _fechaInicio;
    if (fi == null) return 'Fecha y hora de inicio *';
    final h = (_hora?.hour ?? 0).toString().padLeft(2, '0');
    final m = (_hora?.minute ?? 0).toString().padLeft(2, '0');
    return '${fi.day}/${fi.month}/${fi.year}  ·  $h:$m';
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _errorMsg = null);

    if (_fechaInicio == null) {
      setState(() => _errorMsg = 'Selecciona fecha y hora de inicio.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedArtwork == null) {
      setState(() => _errorMsg = 'Selecciona una obra.');
      return;
    }

    final precioBase =
        double.tryParse(_precioBaseCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (precioBase <= 0) {
      setState(() => _errorMsg = 'El precio base debe ser mayor a cero.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auction = await ref.read(auctionsRepositoryProvider).createAuction(
            obraId: _selectedArtwork!.id,
            precioBase: precioBase,
            duracionDias: _duracionDias,
            fechaInicio: _fechaInicio!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Subasta abierta'),
          backgroundColor: AppColors.selvaAndina,
        ),
      );
      context.go('/auctions/${auction.id}');
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final artworksAsync = ref.watch(myArtworksForAuctionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.oroClaro),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Abrir subasta',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Obra ──────────────────────────────────────────────────────
              const SectionLabel(
                icon: Icons.image_outlined,
                label: 'Obra a subastar',
              ),
              const SizedBox(height: 10),
              artworksAsync.when(
                loading: () => const ArtworksLoading(),
                error: (e, _) => ArtworksError(error: e.toString()),
                data: (list) {
                  if (list.isEmpty) return const ArtworksEmpty();
                  _selectedArtwork ??= list.first;
                  return DropdownButtonFormField<ArtworkModel>(
                    key: ValueKey(_selectedArtwork?.id),
                    initialValue: _selectedArtwork,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.palette_outlined),
                      labelText: 'Selecciona una obra *',
                    ),
                    items: list
                        .map((a) =>
                            DropdownMenuItem(value: a, child: Text(a.titulo)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedArtwork = v),
                    validator: (v) => v == null ? 'Selecciona una obra' : null,
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Precio base ───────────────────────────────────────────────
              const SectionLabel(
                icon: Icons.payments_outlined,
                label: 'Precio base',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _precioBaseCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_outlined),
                  labelText: 'Precio base *',
                  hintText: 'Ej: 250.000',
                  prefixText: r'$ ',
                ),
                validator: (v) {
                  final n =
                      double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Ingresa un precio válido';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Duración ──────────────────────────────────────────────────
              const SectionLabel(
                icon: Icons.date_range_outlined,
                label: 'Duración',
              ),
              const SizedBox(height: 6),
              DuracionSlider(
                value: _duracionDias,
                onChanged: (v) => setState(() => _duracionDias = v),
              ),

              const SizedBox(height: 16),

              // ── Fecha y hora ──────────────────────────────────────────────
              const SectionLabel(
                icon: Icons.schedule_outlined,
                label: 'Inicio de la subasta',
              ),
              const SizedBox(height: 10),
              DateTimePicker(
                label: _fechaLabel,
                hasValue: _fechaInicio != null,
                onTap: _pickStartDateTime,
              ),

              const SizedBox(height: 20),

              // ── Error ─────────────────────────────────────────────────────
              if (_errorMsg != null) ...[
                ErrorBanner(message: _errorMsg!),
                const SizedBox(height: 16),
              ],

              // ── Botón ─────────────────────────────────────────────────────
              SubmitButton(
                isSubmitting: _isSubmitting,
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
