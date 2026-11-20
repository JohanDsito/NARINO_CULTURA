import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';

/// Mini mapa fijo (OpenStreetMap) con el punto del evento; al tocarlo abre
/// el mapa completo.
class EventoMapa extends StatelessWidget {
  const EventoMapa({
    super.key,
    required this.latitud,
    required this.longitud,
    required this.onAbrir,
  });

  final double latitud;
  final double longitud;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final punto = LatLng(latitud, longitud);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: punto,
                initialZoom: 15,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
                onTap: (_, __) => onAbrir(),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.narino_cultura.app',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: punto,
                    width: 44,
                    height: 44,
                    child: Icon(Icons.location_on_rounded,
                        size: 44, color: nc.eventos.fill),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('© OpenStreetMap',
            style: AppTypography.caption(color: nc.textMuted)),
      ],
    );
  }
}
