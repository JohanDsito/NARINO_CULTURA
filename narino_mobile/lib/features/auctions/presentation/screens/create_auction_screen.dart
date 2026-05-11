import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../providers/auctions_provider.dart';

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
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: ThemeData(
          colorScheme:
              const ColorScheme.light(primary: AppColors.tierraProfunda),
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
              const _SectionLabel(
                icon: Icons.image_outlined,
                label: 'Obra a subastar',
              ),
              const SizedBox(height: 10),
              artworksAsync.when(
                loading: () => const _ArtworksLoading(),
                error: (e, _) => _ArtworksError(error: e.toString()),
                data: (list) {
                  if (list.isEmpty) return const _ArtworksEmpty();
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
              const _SectionLabel(
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
              const _SectionLabel(
                icon: Icons.date_range_outlined,
                label: 'Duración',
              ),
              const SizedBox(height: 6),
              _DuracionSlider(
                value: _duracionDias,
                onChanged: (v) => setState(() => _duracionDias = v),
              ),

              const SizedBox(height: 16),

              // ── Fecha y hora ──────────────────────────────────────────────
              const _SectionLabel(
                icon: Icons.schedule_outlined,
                label: 'Inicio de la subasta',
              ),
              const SizedBox(height: 10),
              _DateTimePicker(
                label: _fechaLabel,
                hasValue: _fechaInicio != null,
                onTap: _pickStartDateTime,
              ),

              const SizedBox(height: 20),

              // ── Error ─────────────────────────────────────────────────────
              if (_errorMsg != null) ...[
                _ErrorBanner(message: _errorMsg!),
                const SizedBox(height: 16),
              ],

              // ── Botón ─────────────────────────────────────────────────────
              _SubmitButton(
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

// ─── Widgets del formulario ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMutedLight),
        const SizedBox(width: 6),
        Text(
          label,
          style:
              AppTypography.labelSemiBold(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}

class _DuracionSlider extends StatelessWidget {
  const _DuracionSlider({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  String get _label {
    if (value == 1) return '1 día';
    if (value < 7) return '$value días';
    if (value == 7) return '1 semana';
    if (value == 14) return '2 semanas';
    if (value == 30) return '1 mes';
    return '$value días';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duración',
                style:
                    AppTypography.bodyMedium(color: AppColors.textMutedLight),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tierraPalida,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _label,
                  style: AppTypography.caption(color: AppColors.tierraProfunda),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: AppColors.tierraProfunda,
            inactiveColor: AppColors.borderLight,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 día',
                  style:
                      AppTypography.caption(color: AppColors.textMutedLight)),
              Text('30 días',
                  style:
                      AppTypography.caption(color: AppColors.textMutedLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSubtleLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? AppColors.tierraProfunda : AppColors.borderLight,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: hasValue
                  ? AppColors.tierraProfunda
                  : AppColors.textMutedLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium(
                  color: hasValue
                      ? AppColors.textPrimaryLight
                      : AppColors.textMutedLight,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
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
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        icon: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.gavel_outlined),
        label: Text(
          isSubmitting ? 'Abriendo...' : 'Abrir subasta',
          style: AppTypography.buttonText(color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Estados de obras ─────────────────────────────────────────────────────────

class _ArtworksLoading extends StatelessWidget {
  const _ArtworksLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
            color: AppColors.tierraProfunda, strokeWidth: 2),
      ),
    );
  }
}

class _ArtworksError extends StatelessWidget {
  const _ArtworksError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child:
          Text(error, style: AppTypography.bodySmall(color: AppColors.error)),
    );
  }
}

class _ArtworksEmpty extends StatelessWidget {
  const _ArtworksEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppColors.textMutedLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No tienes obras disponibles para subastar.',
              style:
                  AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
