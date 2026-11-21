import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/event_model.dart';
import '../../widgets/eventos_ui.dart';

class EventosVistaLista extends StatelessWidget {
  const EventosVistaLista({
    super.key,
    required this.eventos,
    required this.verPasados,
    required this.onTogglePasados,
    required this.hayBusqueda,
  });

  final List<EventModel> eventos;
  final bool verPasados;
  final VoidCallback onTogglePasados;
  final bool hayBusqueda;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final hoy = soloDia(DateTime.now());
    final semana = hoy.add(const Duration(days: 7));
    final proximos = eventos.where((e) => !e.esPasado).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final pasados = eventos.where((e) => e.esPasado).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    final grupos = <(String, List<EventModel>)>[
      (
        'Hoy',
        proximos.where((e) => soloDia(e.fecha.toLocal()) == hoy).toList()
      ),
      (
        'Esta semana',
        proximos.where((e) {
          final d = soloDia(e.fecha.toLocal());
          return d.isAfter(hoy) && d.isBefore(semana);
        }).toList()
      ),
      (
        'Más adelante',
        proximos
            .where((e) => !soloDia(e.fecha.toLocal()).isBefore(semana))
            .toList()
      ),
    ];

    if (proximos.isEmpty && (!verPasados || pasados.isEmpty)) {
      return Column(
        children: [
          NcEmptyState(
            icon: Icons.event_busy_outlined,
            accent: nc.eventos,
            title: hayBusqueda
                ? 'Nada con esa búsqueda'
                : 'No hay eventos próximos',
            message: hayBusqueda
                ? 'Prueba con otra palabra o quita el filtro de tipo.'
                : 'Pronto habrá conciertos, ferias y talleres en la agenda.',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          if (pasados.isNotEmpty)
            TextButton(
              onPressed: onTogglePasados,
              child: const Text('Ver eventos pasados'),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (titulo, lista) in grupos)
            if (lista.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(titulo,
                    style:
                        AppTypography.displaySemiBold(color: nc.textPrimary)),
              ),
              for (final e in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EventoCard(event: e),
                ),
              const SizedBox(height: 8),
            ],
          if (pasados.isNotEmpty)
            Center(
              child: TextButton.icon(
                onPressed: onTogglePasados,
                icon: Icon(verPasados
                    ? Icons.expand_less_rounded
                    : Icons.history_rounded),
                label: Text(verPasados
                    ? 'Ocultar eventos pasados'
                    : 'Ver eventos pasados (${pasados.length})'),
              ),
            ),
          if (verPasados)
            for (final e in pasados)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EventoCard(event: e),
              ),
        ],
      ),
    );
  }
}
