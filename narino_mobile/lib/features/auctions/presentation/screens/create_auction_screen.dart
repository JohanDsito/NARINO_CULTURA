import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../artworks/domain/artwork_model.dart';
import '../providers/auctions_provider.dart';

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

    if (date == null) return;
    if (!mounted) return;
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

  Future<void> _submit() async {
    if (_fechaInicio == null) {
      setState(() => _errorMsg = 'Selecciona fecha y hora de inicio.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final artwork = _selectedArtwork;
    if (artwork == null) {
      setState(() => _errorMsg = 'Selecciona una obra.');
      return;
    }

    final precioBase =
        double.tryParse(_precioBaseCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (precioBase <= 0) {
      setState(() => _errorMsg = 'El precio base debe ser mayor a cero.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });

    try {
      final auction = await ref.read(auctionsRepositoryProvider).createAuction(
            obraId: artwork.id,
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

  @override
  Widget build(BuildContext context) {
    final artworksAsync = ref.watch(myArtworksForAuctionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Abrir subasta',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.oroClaro),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Obra a subastar',
                style: AppTypography.labelSemiBold(
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              artworksAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppColors.tierraProfunda,
                    ),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withAlpha(77)),
                  ),
                  child: Text(
                    e.toString(),
                    style: AppTypography.bodySmall(color: AppColors.error),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        'No tienes obras disponibles para subastar.',
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }

                  _selectedArtwork ??= list.first;

                  return DropdownButtonFormField<ArtworkModel>(
                    key: ValueKey(_selectedArtwork?.id),
                    initialValue: _selectedArtwork,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.image_outlined),
                      labelText: 'Selecciona una obra *',
                    ),
                    items: list
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.titulo),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedArtwork = v),
                    validator: (v) => v == null ? 'Selecciona una obra' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioBaseCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_outlined),
                  labelText: 'Precio base *',
                  hintText: 'Ej: 250000',
                ),
                validator: (v) {
                  final n =
                      double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Ingresa un precio válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Duración (días): $_duracionDias',
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Slider(
                value: _duracionDias.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: AppColors.tierraProfunda,
                onChanged: (v) => setState(() => _duracionDias = v.round()),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickStartDateTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSubtleLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _fechaInicio == null
                          ? AppColors.borderLight
                          : AppColors.tierraProfunda,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _fechaInicio == null
                            ? AppColors.textMutedLight
                            : AppColors.tierraProfunda,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fechaInicio == null
                              ? 'Fecha y hora de inicio *'
                              : '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year} · ${_hora?.hour.toString().padLeft(2, '0')}:${_hora?.minute.toString().padLeft(2, '0')}',
                          style: AppTypography.bodyMedium(
                            color: _fechaInicio == null
                                ? AppColors.textMutedLight
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withAlpha(77)),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: AppTypography.bodySmall(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.gavel_outlined),
                  label: Text(
                    _isSubmitting ? 'Abriendo...' : 'Abrir subasta',
                    style: AppTypography.buttonText(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
