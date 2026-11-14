import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';
import '../../../domain/musician_model.dart';
import '../../providers/musician_provider.dart';

/// Botón Seguir / Siguiendo conectado a [seguidosProvider].
class SeguirButton extends ConsumerWidget {
  const SeguirButton({super.key, required this.musician, this.compact = false});

  final MusicianModel musician;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final logueado = ref.watch(currentUserRoleProvider).valueOrNull != null;
    if (!logueado) return const SizedBox.shrink();
    // La lista de `musicians/following/` es la fuente de verdad.
    final sigue = ref.watch(seguidosProvider).sigue(musician.slug);

    return Semantics(
      button: true,
      toggled: sigue,
      label: sigue
          ? 'Dejar de seguir a ${musician.name}'
          : 'Seguir a ${musician.name}',
      excludeSemantics: true,
      child: NcPressable(
        onTap: () async {
          HapticFeedback.selectionClick();
          final ok =
              await ref.read(seguidosProvider.notifier).alternar(musician.slug);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('No se pudo actualizar. Intenta de nuevo.')));
          }
        },
        pressedScale: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20, vertical: compact ? 8 : 12),
          decoration: BoxDecoration(
            color: sigue ? Colors.transparent : nc.musica.fill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: sigue ? nc.border : nc.musica.fill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sigue ? Icons.check_rounded : Icons.add_rounded,
                  size: compact ? 16 : 18,
                  color: sigue ? nc.textPrimary : nc.musica.onFill),
              const SizedBox(width: 4),
              Text(sigue ? 'Siguiendo' : 'Seguir',
                  style: AppTypography.labelMedium(
                          color: sigue ? nc.textPrimary : nc.musica.onFill)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
