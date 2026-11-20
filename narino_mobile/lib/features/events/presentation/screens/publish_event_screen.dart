import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../providers/events_provider.dart';
import 'publish_event_screen/evento_cuando_section.dart';
import 'publish_event_screen/evento_datos_section.dart';
import 'publish_event_screen/evento_flyer_section.dart';
import 'publish_event_screen/evento_tipo_section.dart';

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
            EventoTipoSection(
              tipo: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
            const SizedBox(height: 16),
            EventoDatosSection(
              nombre: _nombreCtrl,
              lugar: _lugarCtrl,
              descripcion: _descCtrl,
            ),
            const SizedBox(height: 16),
            EventoCuandoSection(
              inicio: _inicio,
              duracion: _duracion,
              mostrarError: _intentado,
              onElegirFecha: _elegirFecha,
              onDuracion: (d) => setState(() => _duracion = d),
            ),
            const SizedBox(height: 16),
            EventoFlyerSection(flyer: _flyerCtrl),
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
