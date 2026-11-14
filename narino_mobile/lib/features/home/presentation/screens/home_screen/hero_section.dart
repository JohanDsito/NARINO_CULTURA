import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/nc_theme.dart';
import 'hero_image.dart';

/// Hero: kicker en oro, título con degradado (oscuro), texto, dos acciones e
/// imagen destacada (la obra más vista).
class HeroSection extends ConsumerWidget {
  const HeroSection({super.key, required this.onSecondaryFallback});

  /// Acción secundaria para quien no publica (lleva a la agenda).
  final VoidCallback onSecondaryFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nc = context.nc;
    final role = ref.watch(currentUserRoleProvider).valueOrNull ?? '';

    final (String label, VoidCallback onTap) secondary = switch (role) {
      'artista' => (
          'Publicar una obra',
          () => context.push('/artworks/publish')
        ),
      'gestor' || 'admin' => (
          'Publicar un evento',
          () => context.push('/events/new')
        ),
      _ => ('Ver la agenda cultural', onSecondaryFallback),
    };

    final title = Text(
      'La cultura viva de Nariño en un solo ecosistema',
      style: AppTypography.displayBlack(color: nc.textPrimary)
          .copyWith(fontSize: 36, height: 1.06),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('El alma del Carnaval',
              style: AppTypography.kicker(color: nc.oroA.ink)),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: nc.isDark
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, AppColors.azulNeon],
                    ).createShader(r),
                    child: title,
                  )
                : title,
          ),
          const SizedBox(height: 16),
          Text(
            'Conecta con artesanos, descubre el lente de nuestros fotógrafos, '
            'adquiere obras maestras y vibra con los músicos locales.',
            style: AppTypography.bodyLarge(color: nc.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/catalog'),
              child: const Text('Explorar obras'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: secondary.$2,
              child: Text(secondary.$1),
            ),
          ),
          const SizedBox(height: 28),
          const HeroImage(),
        ],
      ),
    );
  }
}
