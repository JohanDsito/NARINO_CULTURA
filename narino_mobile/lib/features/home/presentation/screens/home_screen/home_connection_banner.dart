import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_error.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../home_screen.dart';
import 'agenda_section.dart';
import 'featured_strip.dart';

/// Aviso de Inicio cuando no se pudo cargar nada del servidor (MO-DISP-01).
///
/// Solo aparece si fallan a la vez las obras destacadas y la agenda: si falla
/// una sola, esa sección ya muestra su propio estado y no hace falta alarmar.
class HomeConnectionBanner extends ConsumerWidget {
  const HomeConnectionBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(homeFeaturedArtworksProvider(kHomeFeaturedLimit));
    final events = ref.watch(homeUpcomingEventsProvider(kHomeAgendaLimit));
    if (!featured.hasError || !events.hasError) return const SizedBox.shrink();

    final error = featured.error;
    final message = error is String ? error : ApiError.sinConexion;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: NcBanner.error(
        context,
        message,
        actionLabel: 'Reintentar',
        onAction: onRetry,
      ),
    );
  }
}
