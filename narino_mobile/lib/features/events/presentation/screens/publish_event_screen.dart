import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/events_provider.dart';

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

  DateTime? _fecha;
  String _tipo = 'concierto';
  File? _flyer;

  final List<String> _tipos = const [
    'concierto',
    'exposicion',
    'taller',
    'feria',
    'convocatoria',
    'otro',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    _descCtrl.dispose();
    _artistasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFlyer() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (xfile == null) return;
    final file = File(xfile.path);
    setState(() => _flyer = file);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _fecha ?? now,
    );
    if (!mounted) return;
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha ?? now),
    );
    if (!mounted) return;
    if (time == null) return;
    setState(() {
      _fecha =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  List<String> _parseArtistIds() {
    final raw = _artistasCtrl.text.trim();
    if (raw.isEmpty) return [];
    final parts = raw.split(',');
    final ids = <String>[];
    for (final p in parts) {
      final v = p.trim();
      if (v.isNotEmpty) ids.add(v);
    }
    return ids;
  }

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Publicar evento',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del evento',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('tipo_$_tipo'),
                    initialValue: _tipo,
                    items: _tipos
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t[0].toUpperCase() + t.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lugarCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lugar',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fecha == null
                              ? 'Fecha y hora'
                              : 'Fecha: ${_fmtDateTime(_fecha!)}',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _pickDateTime,
                        child: const Text('Elegir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _artistasCtrl,
                    decoration: const InputDecoration(
                      labelText:
                          'Artistas relacionados (IDs separados por coma)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Flyer / imagen',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: _pickFlyer,
                        child: const Text('Seleccionar'),
                      ),
                    ],
                  ),
                  if (_flyer != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _flyer!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  if (state.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: AppTypography.bodySmall(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.indigoNoche,
                        foregroundColor: Colors.white,
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Publicar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDateTime(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm/$yyyy $hh:$mi';
}
