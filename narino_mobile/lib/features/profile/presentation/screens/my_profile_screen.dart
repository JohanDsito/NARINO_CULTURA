import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/presentation/providers/favorites_provider.dart';
import 'my_profile_screen/count_badge.dart';
import 'my_profile_screen/menu_section.dart';
import 'my_profile_screen/menu_tile.dart';
import 'my_profile_screen/musician_section.dart';
import 'my_profile_screen/profile_preview_card.dart';
import 'my_profile_screen/section_label.dart';
import 'my_profile_screen/theme_toggle_tile.dart';
import 'my_profile_screen/unverified_banner.dart';
import 'my_profile_screen/web_space_section.dart';

final _authRepoProvider = Provider<AuthRepository>((ref) => AuthRepository());

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProfileProvider.notifier).loadMyProfile();
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás segura de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {}
    ref.read(myProfileProvider.notifier).reset();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProfileProvider);
    final favState = ref.watch(favoritesProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final isArtistOrAdmin = role == 'artista' || role == 'admin';

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.tierraProfunda),
        ),
      );
    }

    final profile = state.profile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        elevation: 0,
        title: Text(
          'Perfil',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Vista previa pública ─────────────────────────────────
            ProfilePreviewCard(
              profile: profile,
              favCount: favState.favorites.length,
            ),

            // ── Mi espacio web (solo si hay al menos un link con valor) ─
            if (profile?.redesSociales.entries
                    .any((e) => e.value.trim().isNotEmpty) ==
                true)
              WebSpaceSection(links: profile!.redesSociales),

            // ── Mi contenido (según rol) ──────────────────────────────
            if (isArtistOrAdmin) ...[
              const SectionLabel(label: 'Mi contenido'),
              MenuSection(children: [
                if (profile?.disciplina != 'Música')
                  MenuTile(
                    icon: Icons.palette_outlined,
                    title: 'Mis obras',
                    subtitle: 'Ver y gestionar tus obras publicadas',
                    onTap: () => context.push('/profile/my-artworks'),
                  ),
                MenuTile(
                  icon: Icons.collections_outlined,
                  title: 'Mi portafolio',
                  subtitle: 'Imágenes y videos de tu trabajo',
                  onTap: () => context.push('/profile/portfolio'),
                ),
                MenuTile(
                  icon: Icons.bar_chart_outlined,
                  title: 'Mis ventas',
                  subtitle: 'Historial de ventas',
                  onTap: () => context.push('/marketplace/sales'),
                ),
                if (profile?.disciplina.trim().isNotEmpty == true)
                  MenuTile(
                    icon: Icons.analytics_outlined,
                    title: 'Mis estadísticas',
                    subtitle: 'Visitas, seguidores e ingresos',
                    onTap: () => context.push('/profile/stats'),
                  ),
              ]),
              // Sección exclusiva para músicos
              if (profile?.disciplina == 'Música')
                const MusicianSection(),
            ],
            const SectionLabel(label: 'Mis compras'),
            MenuSection(children: [
              MenuTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Mis compras',
                subtitle: 'Historial de compras',
                onTap: () => context.push('/marketplace/purchases'),
              ),
            ]),

            // ── Mi actividad ─────────────────────────────────────────
            const SectionLabel(label: 'Mi actividad'),
            MenuSection(children: [
              MenuTile(
                icon: Icons.people_outline,
                title: 'Artistas que sigo',
                subtitle: 'Ver tu lista de artistas seguidos',
                onTap: () => context.push('/profile/following'),
              ),
              MenuTile(
                icon: Icons.favorite_outline,
                title: 'Mis favoritos',
                subtitle: 'Obras guardadas',
                trailing: favState.favorites.isNotEmpty
                    ? CountBadge(count: favState.favorites.length)
                    : null,
                onTap: () => context.push('/marketplace/favorites'),
              ),
            ]),

            // ── Configuración ─────────────────────────────────────────
            const SectionLabel(label: 'Configuración'),
            MenuSection(children: [
              MenuTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones de eventos',
                subtitle: 'Configura qué eventos te interesan',
                onTap: () =>
                    context.push('/events/notification-preferences'),
              ),
              const ThemeToggleTile(),
              MenuTile(
                icon: Icons.shield_outlined,
                title: 'Privacidad',
                subtitle: 'Política de privacidad y tratamiento de datos',
                onTap: () => context.push('/profile/privacy'),
              ),
              MenuTile(
                icon: Icons.alternate_email_outlined,
                title: 'Cambiar correo',
                subtitle: 'Actualiza tu correo electrónico',
                onTap: () => context.push('/profile/change-email'),
              ),
              MenuTile(
                icon: Icons.security_outlined,
                title: 'Sesiones activas',
                subtitle: 'Ver y revocar accesos',
                onTap: () => context.push('/profile/sessions'),
              ),
              MenuTile(
                icon: Icons.delete_outline,
                title: 'Eliminar cuenta',
                subtitle: 'Desactiva tu cuenta de forma permanente',
                accentColor: AppColors.error,
                onTap: () => context.push('/profile/delete-account'),
              ),
            ]),

            // ── Correo sin verificar ─────────────────────────────────
            if (profile?.esVerificado == false)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: UnverifiedBanner(authProvider: _authRepoProvider),
              ),

            // ── Cerrar sesión ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_outlined),
                  label: Text(
                    'Cerrar sesión',
                    style: AppTypography.labelSemiBold(color: AppColors.error),
                  ),
                  onPressed: _logout,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
