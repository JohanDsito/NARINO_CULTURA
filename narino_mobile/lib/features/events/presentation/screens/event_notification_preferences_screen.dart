import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../../notifications/data/notifications_service.dart';
import '../widgets/eventos_ui.dart';

const _kCache = 'event_notification_preferences';
const _kMaxArtistas = 10;

/// Avisos de eventos: activar/desactivar, por tipo y por artista.
///
/// Contrato (`GET`/`PATCH /notifications/event-preferences/`):
/// `{all_enabled, categories: {concierto: bool, …}, favorite_artists: [..]}`.
/// Mientras el backend no tenga el endpoint, se guarda en el teléfono.
class EventNotificationPreferencesScreen extends ConsumerStatefulWidget {
  const EventNotificationPreferencesScreen({super.key, this.service});

  /// Para pruebas; por defecto [NotificationsService].
  final NotificationsService? service;

  @override
  ConsumerState<EventNotificationPreferencesScreen> createState() =>
      _EventNotificationPreferencesScreenState();
}

class _EventNotificationPreferencesScreenState
    extends ConsumerState<EventNotificationPreferencesScreen> {
  final _storage = const FlutterSecureStorage();
  late final NotificationsService _service =
      widget.service ?? NotificationsService();
  final _artistaCtrl = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  bool _todas = true;
  final Map<String, bool> _tipos = {for (final t in kTiposEvento) t: true};
  final List<String> _artistas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _artistaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final local = await _storage.read(key: _kCache);
      if (local != null) _aplicar(jsonDecode(local) as Map<String, dynamic>);
    } catch (_) {}
    try {
      final data = await _service.getEventPreferences();
      _aplicar(data);
      try {
        await _storage.write(key: _kCache, value: jsonEncode(data));
      } catch (_) {}
    } catch (_) {
      // Sin endpoint todavía: se queda lo guardado en el teléfono.
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _aplicar(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _todas = data['all_enabled'] as bool? ?? true;
      final cats = data['categories'];
      if (cats is Map) {
        cats.forEach((k, v) {
          if (_tipos.containsKey(k) && v is bool) _tipos[k.toString()] = v;
        });
      }
      _artistas
        ..clear()
        ..addAll(List<String>.from(data['favorite_artists'] as List? ?? []));
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final data = {
      'all_enabled': _todas,
      'categories': _tipos,
      'favorite_artists': _artistas,
    };
    final messenger = ScaffoldMessenger.of(context);
    String aviso;
    var cerrar = true;
    try {
      await _service.saveEventPreferences(data);
      aviso = 'Listo, guardamos tus avisos de eventos';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == null || code == 404 || code == 405) {
        // Antes esto mostraba "Error al guardar" y no dejaba salir.
        aviso = 'Guardamos tus avisos en este teléfono';
      } else {
        aviso = 'No pudimos guardar tus avisos. Intenta de nuevo.';
        cerrar = false;
      }
    } catch (_) {
      aviso = 'Guardamos tus avisos en este teléfono';
    }
    if (cerrar) {
      try {
        await _storage.write(key: _kCache, value: jsonEncode(data));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _guardando = false);
    messenger.showSnackBar(SnackBar(content: Text(aviso)));
    if (cerrar) context.pop();
  }

  void _agregarArtista() {
    final nombre = _artistaCtrl.text.trim();
    if (nombre.isEmpty) return;
    String? error;
    if (_artistas.any((a) => a.toLowerCase() == nombre.toLowerCase())) {
      error = 'Ya está en tu lista';
    } else if (_artistas.length >= _kMaxArtistas) {
      error = 'Puedes seguir hasta $_kMaxArtistas artistas aquí';
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      _artistas.add(nombre);
      _artistaCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos de eventos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ── Interruptor general ──
                NcCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                  child: Row(
                    children: [
                      NcAccentIcon(
                          icon: _todas
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          accent: nc.eventos,
                          size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avisarme de eventos',
                                style: AppTypography.labelSemiBold(
                                    color: nc.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                                _todas
                                    ? 'Te contamos cuando haya eventos que te gusten'
                                    : 'No recibirás avisos de eventos',
                                style: AppTypography.bodySmall(
                                    color: nc.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _todas,
                        onChanged: (v) => setState(() => _todas = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Por tipo ──
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _todas ? 1 : 0.45,
                  child: IgnorePointer(
                    ignoring: !_todas,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const NcSectionHeader(
                            title: '¿De qué tipo?',
                            padding: EdgeInsets.symmetric(horizontal: 4)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in kTiposEvento)
                              _ChipTipo(
                                tipo: t,
                                activo: _tipos[t] ?? true,
                                onTap: () => setState(
                                    () => _tipos[t] = !(_tipos[t] ?? true)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Por artista ──
                        const NcSectionHeader(
                            title: 'Artistas que no te quieres perder',
                            padding: EdgeInsets.symmetric(horizontal: 4)),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                              'Te avisamos cuando publiquen un evento nuevo.',
                              style: AppTypography.bodySmall(
                                  color: nc.textSecondary)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _artistaCtrl,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _agregarArtista(),
                                decoration: const InputDecoration(
                                  hintText: 'Nombre del artista o banda',
                                  prefixIcon: Icon(Icons.person_search_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: 'Agregar',
                              onPressed: _agregarArtista,
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_artistas.isEmpty)
                          Text('Aún no agregas artistas.',
                              style:
                                  AppTypography.bodySmall(color: nc.textMuted))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final a in _artistas)
                                InputChip(
                                  label: Text(a),
                                  avatar: Icon(Icons.star_rounded,
                                      size: 16, color: nc.oroA.ink),
                                  onDeleted: () =>
                                      setState(() => _artistas.remove(a)),
                                  deleteButtonTooltipMessage: 'Quitar $a',
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _cargando
          ? null
          : NcGlassBottomBar(
              child: NcPrimaryButton(
                label: 'Guardar avisos',
                icon: Icons.check_rounded,
                loading: _guardando,
                onPressed: _guardar,
              ),
            ),
    );
  }
}

class _ChipTipo extends StatelessWidget {
  const _ChipTipo({
    required this.tipo,
    required this.activo,
    required this.onTap,
  });

  final String tipo;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final a = tipoAccent(nc, tipo);
    return Semantics(
      toggled: activo,
      button: true,
      label: tipoNombre(tipo),
      excludeSemantics: true,
      child: NcPressable(
        onTap: onTap,
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? a.fill : nc.itemFill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: activo ? a.fill : nc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activo ? Icons.check_rounded : tipoIcon(tipo),
                  size: 16, color: activo ? a.onFill : a.ink),
              const SizedBox(width: 6),
              Text(tipoNombre(tipo),
                  style: AppTypography.labelMedium(
                          color: activo ? a.onFill : nc.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
