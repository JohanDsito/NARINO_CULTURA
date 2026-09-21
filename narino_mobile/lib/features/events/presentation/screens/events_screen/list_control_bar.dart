import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/events_state.dart';
import '../../providers/events_provider.dart';

class ListControlBar extends ConsumerWidget {
  const ListControlBar({super.key, required this.state});

  final EventsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text(
                '${state.filteredEvents.length} eventos',
                style: AppTypography.bodySmall(color: textMuted),
              ),
              const Spacer(),
              Text(
                'Incluir pasados',
                style: AppTypography.caption(color: textSecondary),
              ),
              Switch(
                value: state.mostrarPasados,
                activeThumbColor: cs.primary,
                onChanged: (_) =>
                    ref.read(eventsProvider.notifier).togglePasados(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}
