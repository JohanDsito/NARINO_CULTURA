import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/events_provider.dart';

// ─── Constantes ───────────────────────────────────────────────────────────────

const _kTipos = [
  'concierto',
  'exposicion',
  'taller',
  'feria',
  'convocatoria',
  'otro',
];

// ─── Pantalla principal ───────────────────────────────────────────────────────

class PublishEventScreen extends ConsumerStatefulWidget {
  const PublishEventScreen({super.key});

  @override
  ConsumerState<PublishEventScreen> createState() => _PublishEventScreenState();
}

class _PublishEventScreenState extends ConsumerState<PublishEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _artistasCtrl = TextEditingController();

  final _lugarFocus = FocusNode();
  final _descFocus = FocusNode();

  DateTime? _fecha;
  String _tipo = 'concierto';
  File? _flyer;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    _descCtrl.dispose();
    _artistasCtrl.dispose();
    _lugarFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _pickFlyer() async {
    final xfile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (xfile != null) setState(() => _flyer = File(xfile.path));
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _fecha ?? now,
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha ?? now),
    );
    if (!mounted || time == null) return;

    setState(() {
      _fecha =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  List<String> _parseArtistIds() => _artistasCtrl.text
      .trim()
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora.')),
      );
      return;
    }

    final ok = await ref.read(eventsProvider.notifier).publishEvent(
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipo,
          fecha: _fecha!.toIso8601String(),
          lugar: _lugarCtrl.text.trim(),
          descripcion: _descCtrl.text.trim(),
          artistas: _parseArtistIds(),
          flyer: _flyer,
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento publicado.')),
      );
      context.go('/events');
    } else {
      final err = ref.read(eventsProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        leading: const BackButton(color: AppColors.oroClaro),
        title: Text(
          'Publicar evento',
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
              // ── Nombre ────────────────────────────────────────────────
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_lugarFocus),
                decoration: const InputDecoration(
                  labelText: 'Nombre del evento *',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── Tipo ──────────────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                items: _kTipos
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (v) => setState(() => _tipo = v ?? _tipo),
                decoration: const InputDecoration(
                  labelText: 'Tipo de evento',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // ── Lugar ─────────────────────────────────────────────────
              TextFormField(
                controller: _lugarCtrl,
                focusNode: _lugarFocus,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_descFocus),
                decoration: const InputDecoration(
                  labelText: 'Lugar *',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── Fecha y hora ──────────────────────────────────────────
              _DateTimeTile(
                fecha: _fecha,
                onTap: isLoading ? null : _pickDateTime,
              ),
              const SizedBox(height: 14),

              // ── Descripción ───────────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.notes_outlined),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),

              // ── Artistas ──────────────────────────────────────────────
              TextFormField(
                controller: _artistasCtrl,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Artistas relacionados (IDs, separados por coma)',
                  prefixIcon: Icon(Icons.people_outline),
                ),
              ),
              const SizedBox(height: 16),

              // ── Flyer ─────────────────────────────────────────────────
              _FlyerPicker(
                file: _flyer,
                disabled: isLoading,
                onPick: _pickFlyer,
                onRemove: () => setState(() => _flyer = null),
              ),

              // ── Error ─────────────────────────────────────────────────
              if (state.hasError) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: state.errorMessage!),
              ],

              const SizedBox(height: 24),

              // ── Botón ─────────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: Text(
                    isLoading ? 'Publicando...' : 'Publicar evento',
                    style: AppTypography.buttonText(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Selector de fecha/hora ───────────────────────────────────────────────────

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.fecha, required this.onTap});

  final DateTime? fecha;
  final VoidCallback? onTap;

  String get _label {
    if (fecha == null) return 'Fecha y hora *';
    final dd = fecha!.day.toString().padLeft(2, '0');
    final mm = fecha!.month.toString().padLeft(2, '0');
    final hh = fecha!.hour.toString().padLeft(2, '0');
    final mi = fecha!.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha!.year}  ·  $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final hasValue = fecha != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? cs.primary : border,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: hasValue ? cs.primary : textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _label,
                style: AppTypography.bodyMedium(
                  color: hasValue ? textPrimary : textMuted,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Selector de flyer ────────────────────────────────────────────────────────

class _FlyerPicker extends StatelessWidget {
  const _FlyerPicker({
    required this.file,
    required this.disabled,
    required this.onPick,
    required this.onRemove,
  });

  final File? file;
  final bool disabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 16, color: textMuted),
            const SizedBox(width: 6),
            Text(
              'Flyer / imagen',
              style: AppTypography.labelSemiBold(color: textSecondary),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: disabled ? null : onPick,
              icon: const Icon(Icons.upload_outlined, size: 16),
              label: Text(file == null ? 'Seleccionar' : 'Cambiar imagen'),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
              ),
            ),
          ],
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  file!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: disabled ? null : onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Banner de error ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
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
