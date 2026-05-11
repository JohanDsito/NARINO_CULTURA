import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../marketplace/presentation/providers/favorites_provider.dart';

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
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás segura de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(_authRepoProvider).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProfileProvider);
    final favState = ref.watch(favoritesProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final isArtist = role == 'artista';

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.obsidiana,
            expandedHeight: 200,
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.edit_outlined, color: AppColors.oroClaro),
                onPressed: () => context.push('/profile/edit'),
              ),
              IconButton(
                icon:
                    const Icon(Icons.logout_outlined, color: Colors.redAccent),
                onPressed: _logout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.obsidiana,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.tierraPalida,
                        backgroundImage: profile?.fotoUrl != null
                            ? NetworkImage(profile!.fotoUrl!)
                            : null,
                        child: profile?.fotoUrl == null
                            ? Text(
                                profile?.nombreArtistico.isNotEmpty == true
                                    ? profile!.nombreArtistico[0].toUpperCase()
                                    : '?',
                                style: AppTypography.displayBold(
                                  color: AppColors.tierraProfunda,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile?.nombreArtistico ?? 'Mi perfil',
                        style: AppTypography.displaySemiBold(
                          color: AppColors.oroClaro,
                        ),
                      ),
                      Text(
                        profile?.disciplina ?? '',
                        style: AppTypography.quoteItalic(
                          color: AppColors.oroClaro.withValues(alpha: 0.7),
                        ).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStat('${profile?.seguidores ?? 0}', 'Seguidores'),
                      const SizedBox(width: 24),
                      _buildStat('${profile?.totalObras ?? 0}', 'Obras'),
                      const SizedBox(width: 24),
                      _buildStat(
                        '${favState.favorites.length}',
                        'Favoritos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    Icons.palette_outlined,
                    'Mis obras',
                    'Ver y gestionar tus obras publicadas',
                    () => context.go('/catalog'),
                  ),
                  _buildMenuTile(
                    Icons.collections_outlined,
                    'Mi portafolio',
                    'Imágenes y videos de tu trabajo',
                    () => context.push('/profile/portfolio'),
                  ),
                  _buildMenuTile(
                    Icons.people_outline,
                    'Artistas que sigo',
                    'Ver tu lista de artistas seguidos',
                    () => context.push('/profile/following'),
                  ),
                  _buildMenuTile(
                    Icons.favorite_outline,
                    'Mis favoritos',
                    'Obras guardadas',
                    () => context.push('/marketplace/favorites'),
                  ),
                  _buildMenuTile(
                    Icons.shopping_bag_outlined,
                    'Mis compras',
                    'Historial de compras',
                    () => context.push('/marketplace/purchases'),
                  ),
                  _buildMenuTile(
                    Icons.notifications_outlined,
                    'Notificaciones de eventos',
                    'Configura qué eventos te interesan',
                    () => context.push('/events/notification-preferences'),
                  ),
                  if (isArtist)
                    _buildMenuTile(
                      Icons.bar_chart_outlined,
                      'Mis ventas',
                      'Historial de ventas (artistas)',
                      () => context.push('/marketplace/sales'),
                    ),
                  if (isArtist && profile?.disciplina.trim().isNotEmpty == true)
                    _buildMenuTile(
                      Icons.bar_chart_outlined,
                      'Mis estadísticas',
                      'Visitas, seguidores e ingresos',
                      () => context.push('/profile/stats'),
                    ),
                  const SizedBox(height: 20),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    Icons.alternate_email_outlined,
                    'Cambiar correo',
                    'Actualiza tu correo electrónico',
                    () => context.push('/profile/change-email'),
                  ),
                  _buildMenuTile(
                    Icons.security_outlined,
                    'Sesiones activas',
                    'Ver y revocar accesos',
                    () => context.push('/profile/sessions'),
                  ),
                  _buildMenuTile(
                    Icons.delete_outline,
                    'Eliminar cuenta',
                    'Desactiva tu cuenta de forma permanente',
                    () => context.push('/profile/delete-account'),
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  const SizedBox(height: 8),
                  if (profile?.esVerificado == false)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.oroAndino.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.oroAndino.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            color: AppColors.oroAndino,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Correo sin verificar',
                                  style: AppTypography.labelSemiBold(
                                    color: AppColors.oroAndino,
                                  ),
                                ),
                                Text(
                                  'Verifica tu correo para acceso completo.',
                                  style: AppTypography.caption(
                                    color: AppColors.oroAndino,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(_authRepoProvider)
                                    .resendVerification();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Correo de verificación enviado ✅'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            child: Text(
                              'Reenviar',
                              style: AppTypography.caption(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.displaySemiBold(
            color: textPrimary,
          ).copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: AppTypography.caption(color: textMuted),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final iconBg = isDark ? AppColors.bgSubtleDark : AppColors.tierraPalida;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.labelSemiBold(color: textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption(color: textMuted),
      ),
      trailing: Icon(Icons.chevron_right, color: textMuted),
      onTap: onTap,
    );
  }
}
