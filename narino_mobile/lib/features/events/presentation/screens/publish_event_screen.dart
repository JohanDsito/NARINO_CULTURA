import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/events_provider.dart';
import '../widgets/eventos_ui.dart';

const _duraciones = <(String, Duration)>[
  ('1 h', Duration(hours: 1)),
  ('2 h', Duration(hours: 2)),
  ('3 h', Duration(hours: 3)),
  ('Medio día', Duration(hours: 5)),
  ('Todo el día', Duration(hours: 10)),
];

/// Publicar un evento en la agenda (acento tomate).
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
  final _flyerCtrl = TextEditingController();

  String _tipo = 'concierto';
  DateTime? _inicio;
  Duration _duracion = const Duration(hours: 2);
  bool _enviando = false;
  bool _intentado = false;

  @override
  void initState() {
    super.initState();
    _flyerCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    _descCtrl.dispose();
    _flyerCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: _inicio ?? now,
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_inicio ?? DateTime(2000, 1, 1, 19)),
    );
    if (!mounted || time == null) return;
    setState(() => _inicio =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _intentado = true);
    if (!_formKey.currentState!.validate() || _inicio == null) return;

    final role = await ref.read(currentUserRoleProvider.future);
    // Gestores y admin publican directo; los artistas quedan en borrador.
    final publicar = role == 'gestor' || role == 'admin';
    setState(() => _enviando = true);
    final ok = await ref.read(eventsProvider.notifier).publishEvent(
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipo,
          fecha: _inicio!.toIso8601String(),
          lugar: _lugarCtrl.text.trim(),
          descripcion: _descCtrl.text.trim(),
          imageUrl: _flyerCtrl.text.trim(),
          isPublished: publicar,
          duracion: _duracion,
        );
    if (!mounted) return;
    setState(() => _enviando = false);
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(publicar
            ? '¡Tu evento ya está en la agenda!'
            : 'Evento guardado como borrador. Un gestor cultural lo '
                'publicará en la agenda.'),
      ));
      context.go('/events');
    } else {
      final err = ref.read(eventsProvider).errorMessage;
      messenger.showSnackBar(
          SnackBar(content: Text(err ?? 'No se pudo guardar el evento.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final esBorrador = !(role == 'gestor' || role == 'admin');
    final fin = _inicio?.add(_duracion);
    final flyer = _flyerCtrl.text.trim();
    final flyerValido = Uri.tryParse(flyer)?.hasScheme == true;

    Widget titulo(String t, {String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t,
                  style: AppTypography.labelSemiBold(color: nc.textPrimary)),
              if (hint != null)
                Text(hint,
                    style: AppTypography.bodySmall(color: nc.textSecondary)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Nuevo evento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            if (esBorrador) ...[
              NcBanner(
                accent: nc.oroA,
                icon: Icons.edit_note_rounded,
                message: 'Tu evento se guardará como borrador y un gestor '
                    'cultural lo publicará en la agenda.',
              ),
              const SizedBox(height: 16),
            ],

            // ── Tipo ──
            NcCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titulo('¿Qué tipo de evento es?'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in kTiposEvento)
                        ChoiceChip(
                          avatar: Icon(tipoIcon(t),
                              size: 16,
                              color: _tipo == t
                                  ? tipoAccent(nc, t).onFill
                                  : tipoAccent(nc, t).ink),
                          label: Text(tipoNombre(t)),
                          selected: _tipo == t,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _tipo = t),
                          selectedColor: tipoAccent(nc, t).fill,
                          side: BorderSide(
                              color: _tipo == t
                                  ? tipoAccent(nc, t).fill
                                  : nc.border),
                          labelStyle: AppTypography.labelMedium(
                            color: _tipo == t
                                ? tipoAccent(nc, t).onFill
                                : nc.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
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
                  titulo('Cuéntanos del evento'),
                  TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 120,
                    decoration: const InputDecoration(
                        labelText: 'Nombre del evento', counterText: ''),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ponle un nombre al evento'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _lugarCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Lugar',
                      hintText: 'Ej.: Teatro Imperial, Pasto',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Indica dónde será'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descCtrl,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 1500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Cuándo ──
            NcCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titulo('¿Cuándo?'),
                  OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _intentado && _inicio == null
                            ? nc.tomateA.fill
                            : nc.border,
                      ),
                    ),
                    icon: const Icon(Icons.event_rounded),
                    label: Text(_inicio == null
                        ? 'Elegir fecha y hora'
                        : '${_inicio!.day}/${_inicio!.month}/${_inicio!.year} · '
                            '${hora(_inicio!)}'),
                  ),
                  if (_intentado && _inicio == null) ...[
                    const SizedBox(height: 6),
                    Text('Elige cuándo empieza',
                        style: AppTypography.bodySmall(color: nc.tomateA.ink)),
                  ],
                  const SizedBox(height: 14),
                  Text('Duración',
                      style:
                          AppTypography.labelMedium(color: nc.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (label, d) in _duraciones)
                        ChoiceChip(
                          label: Text(label),
                          selected: _duracion == d,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _duracion = d),
                          selectedColor: nc.eventos.fill,
                          side: BorderSide(
                              color: _duracion == d
                                  ? nc.eventos.fill
                                  : nc.border),
                          labelStyle: AppTypography.labelMedium(
                            color: _duracion == d
                                ? nc.eventos.onFill
                                : nc.textPrimary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  if (fin != null) ...[
                    const SizedBox(height: 12),
                    Text('Termina a las ${hora(fin)}'
                        '${soloDia(fin) != soloDia(_inicio!) ? ' del día siguiente' : ''}',
                        style: AppTypography.labelSemiBold(
                                color: nc.eventos.ink)
                            .copyWith(fontSize: 14)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Flyer ──
            NcCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titulo('Flyer (opcional)',
                      hint: 'Pega el enlace de una imagen ya publicada '
                          '(el backend aún no permite subir archivos).'),
                  TextFormField(
                    controller: _flyerCtrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Enlace de la imagen',
                      hintText: 'https://…',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      return Uri.tryParse(t)?.hasScheme == true
                          ? null
                          : 'Debe empezar por https://';
                    },
                  ),
                  if (flyerValido) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: CachedNetworkImage(
                          imageUrl: flyer,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                            child: Text('No se pudo cargar la imagen',
                                style: AppTypography.bodySmall(
                                    color: nc.tomateA.ink)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NcGlassBottomBar(
        child: NcPrimaryButton(
          label: esBorrador ? 'Guardar borrador' : 'Publicar en la agenda',
          icon: esBorrador ? Icons.save_outlined : Icons.campaign_outlined,
          loading: _enviando,
          onPressed: _submit,
        ),
      ),
    );
  }
}
