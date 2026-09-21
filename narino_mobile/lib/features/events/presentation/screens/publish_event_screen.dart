import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/events_provider.dart';
import 'publish_event_screen/date_time_tile.dart';
import 'publish_event_screen/error_banner.dart';
import 'publish_event_screen/flyer_picker.dart';

// ─── Constantes ───────────────────────────────────────────────────────────────

// Valores que coinciden con Event.Type del backend
const _kTipos = [
  'CONCIERTO',
  'EXPOSICION',
  'TALLER',
  'FERIA',
  'ESPECTACULO',
  'OTRO',
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
  final _flyerUrlCtrl = TextEditingController();

  final _lugarFocus = FocusNode();
  final _descFocus = FocusNode();

  DateTime? _fecha;
  String _tipo = 'concierto';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    _descCtrl.dispose();
    _artistasCtrl.dispose();
    _flyerUrlCtrl.dispose();
    _lugarFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

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

    final role = await ref.read(currentUserRoleProvider.future);
    final isPublished = role == 'gestor' ||
        role == 'gestor_cultural' ||
        role == 'admin' ||
        role == 'administrador';

    final ok = await ref.read(eventsProvider.notifier).publishEvent(
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipo,
          fecha: _fecha!.toIso8601String(),
          lugar: _lugarCtrl.text.trim(),
          descripcion: _descCtrl.text.trim(),
          artistas: _parseArtistIds(),
          imageUrl: _flyerUrlCtrl.text.trim(),
          isPublished: isPublished,
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
              DateTimeTile(
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
              FlyerPicker(
                controller: _flyerUrlCtrl,
                disabled: isLoading,
              ),

              // ── Error ─────────────────────────────────────────────────
              if (state.hasError) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: state.errorMessage!),
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
