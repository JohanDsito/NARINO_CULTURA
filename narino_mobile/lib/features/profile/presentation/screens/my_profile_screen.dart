import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/user_role_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/storage_utils.dart';
import '../providers/profile_provider.dart';
import '../../domain/profile_model.dart';
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
      await StorageUtils.clearTokens();
    } catch (_) {}
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
            _ProfilePreviewCard(
              profile: profile,
              favCount: favState.favorites.length,
            ),

            // ── Mi contenido (según rol) ──────────────────────────────
            if (isArtistOrAdmin) ...[
              const _SectionLabel(label: 'Mi contenido'),
              _MenuSection(children: [
                _MenuTile(
                  icon: Icons.palette_outlined,
                  title: 'Mis obras',
                  subtitle: 'Ver y gestionar tus obras publicadas',
                  onTap: () => context.go('/catalog'),
                ),
                _MenuTile(
                  icon: Icons.collections_outlined,
                  title: 'Mi portafolio',
                  subtitle: 'Imágenes y videos de tu trabajo',
                  onTap: () => context.push('/profile/portfolio'),
                ),
                _MenuTile(
                  icon: Icons.bar_chart_outlined,
                  title: 'Mis ventas',
                  subtitle: 'Historial de ventas',
                  onTap: () => context.push('/marketplace/sales'),
                ),
                if (profile?.disciplina.trim().isNotEmpty == true)
                  _MenuTile(
                    icon: Icons.analytics_outlined,
                    title: 'Mis estadísticas',
                    subtitle: 'Visitas, seguidores e ingresos',
                    onTap: () => context.push('/profile/stats'),
                  ),
              ]),
            ],
            const _SectionLabel(label: 'Mi contenido'),
            _MenuSection(children: [
              _MenuTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Mis compras',
                subtitle: 'Historial de compras',
                onTap: () => context.push('/marketplace/purchases'),
              ),
            ]),

            // ── Mi actividad ─────────────────────────────────────────
            const _SectionLabel(label: 'Mi actividad'),
            _MenuSection(children: [
              _MenuTile(
                icon: Icons.people_outline,
                title: 'Artistas que sigo',
                subtitle: 'Ver tu lista de artistas seguidos',
                onTap: () => context.push('/profile/following'),
              ),
              _MenuTile(
                icon: Icons.favorite_outline,
                title: 'Mis favoritos',
                subtitle: 'Obras guardadas',
                trailing: favState.favorites.isNotEmpty
                    ? _CountBadge(count: favState.favorites.length)
                    : null,
                onTap: () => context.push('/marketplace/favorites'),
              ),
            ]),

            // ── Configuración ─────────────────────────────────────────
            const _SectionLabel(label: 'Configuración'),
            _MenuSection(children: [
              _MenuTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones de eventos',
                subtitle: 'Configura qué eventos te interesan',
                onTap: () =>
                    context.push('/events/notification-preferences'),
              ),
              _ThemeToggleTile(),
              _MenuTile(
                icon: Icons.shield_outlined,
                title: 'Privacidad',
                subtitle: 'Política de privacidad y tratamiento de datos',
                onTap: () => context.push('/profile/privacy'),
              ),
              _MenuTile(
                icon: Icons.alternate_email_outlined,
                title: 'Cambiar correo',
                subtitle: 'Actualiza tu correo electrónico',
                onTap: () => context.push('/profile/change-email'),
              ),
              _MenuTile(
                icon: Icons.security_outlined,
                title: 'Sesiones activas',
                subtitle: 'Ver y revocar accesos',
                onTap: () => context.push('/profile/sessions'),
              ),
              _MenuTile(
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
                child: _UnverifiedBanner(authProvider: _authRepoProvider),
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

// ─── Tarjeta de vista previa pública ─────────────────────────────────────────

class _ProfilePreviewCard extends ConsumerWidget {
  const _ProfilePreviewCard({
    required this.profile,
    required this.favCount,
  });

  final ProfileModel? profile;
  final int favCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final photoVersion = ref.watch(myProfileProvider).photoVersion;
    final role = ref.watch(currentUserRoleProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta "Así te ven los demás"
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 14, color: textMuted),
              const SizedBox(width: 6),
              Text(
                'Así te ven los demás',
                style: AppTypography.caption(color: textMuted),
              ),
            ],
          ),
        ),

        // Tarjeta contenedora
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Encabezado oscuro (igual al perfil público)
              Container(
                width: double.infinity,
                color: AppColors.obsidiana,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  children: [
                    // key cambia con photoVersion → descarta la imagen cacheada
                    CircleAvatar(
                      key: ValueKey('avatar-$photoVersion'),
                      radius: 46,
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
                      textAlign: TextAlign.center,
                    ),
                    if (profile?.disciplina.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        profile!.disciplina,
                        style: AppTypography.quoteItalic(
                          color: AppColors.oroClaro.withValues(alpha: 0.7),
                        ).copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (role != null) ...[
                      const SizedBox(height: 10),
                      _RoleBadge(role: role),
                    ],
                    const SizedBox(height: 16),
                    // Botón editar perfil dentro del encabezado
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.oroClaro,
                          side: BorderSide(
                            color: AppColors.oroClaro.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon:
                            const Icon(Icons.edit_outlined, size: 15),
                        label: Text(
                          'Editar perfil',
                          style: AppTypography.labelMedium(
                            color: AppColors.oroClaro,
                          ),
                        ),
                        onPressed: () => context.push('/profile/edit'),
                      ),
                    ),
                  ],
                ),
              ),

              // Estadísticas
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _Stat(
                      value: '${profile?.seguidores ?? 0}',
                      label: 'Seguidores',
                    ),
                    _StatDivider(),
                    _Stat(
                      value: '${profile?.totalObras ?? 0}',
                      label: 'Obras',
                    ),
                    _StatDivider(),
                    _Stat(
                      value: '$favCount',
                      label: 'Favoritos',
                    ),
                  ],
                ),
              ),

              // Biografía
              if (profile?.biografia != null &&
                  profile!.biografia!.isNotEmpty) ...[
                Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Text(
                    profile!.biografia!,
                    style: AppTypography.quoteItalic(color: textSecondary)
                        .copyWith(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // Redes sociales
              if (profile?.redesSociales.isNotEmpty == true) ...[
                Divider(height: 1, color: border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile!.redesSociales.entries
                        .take(4)
                        .map((e) => _SocialChip(
                              platform: e.key,
                              url: e.value,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stat dentro de la tarjeta ────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.displaySemiBold(color: textPrimary)
                .copyWith(fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(color: textMuted)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Chip de red social ───────────────────────────────────────────────────────

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.platform, required this.url});

  final String platform;
  final String url;

  IconData get _icon {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'facebook':
        return Icons.facebook_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      case 'website':
        return Icons.language_outlined;
      default:
        return Icons.link_outlined;
    }
  }

  String get _label {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'tiktok':
        return 'TikTok';
      case 'website':
        return 'Web';
      default:
        return platform;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(_icon, size: 14, color: cs.primary),
      label: Text(_label, style: AppTypography.caption(color: cs.primary)),
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

// ─── Badge de tipo de cuenta ──────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  (IconData, String, Color) get _info {
    switch (role) {
      case 'artista':
        return (Icons.palette_outlined, 'Artista', AppColors.selvaAndina);
      case 'comprador':
        return (Icons.explore_outlined, 'Visitante', AppColors.oroAndino);
      case 'gestor':
      case 'gestor_cultural':
        return (Icons.event_outlined, 'Gestor Cultural', AppColors.tierraProfunda);
      case 'admin':
        return (Icons.shield_outlined, 'Administrador', AppColors.error);
      default:
        return (Icons.person_outline, role, AppColors.oroClaro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.caption(color: color)),
        ],
      ),
    );
  }
}

// ─── Etiqueta de sección ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption(color: textMuted)
            .copyWith(letterSpacing: 1.1),
      ),
    );
  }
}

// ─── Contenedor de sección con borde ─────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: children
            .expand((child) => [child, _SectionDivider()])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

// ─── Fila de menú ─────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final iconBg = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final iconColor = accentColor ?? cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor != null
                    ? accentColor!.withValues(alpha: 0.1)
                    : iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSemiBold(
                      color: accentColor ?? textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption(color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? Icon(Icons.chevron_right, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de conteo ──────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count',
        style: AppTypography.caption(color: cs.primary),
      ),
    );
  }
}

// ─── Toggle de tema ───────────────────────────────────────────────────────────

class _ThemeToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final iconBg = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final currentMode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              currentMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : currentMode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.settings_suggest_outlined,
              color: cs.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apariencia',
                  style: AppTypography.labelSemiBold(color: textPrimary),
                ),
                Text(
                  'Tema de la aplicación',
                  style: AppTypography.caption(color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<ThemeMode>(
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle: AppTypography.caption(color: textPrimary)
                  .copyWith(fontSize: 10),
              selectedBackgroundColor: cs.primary,
              selectedForegroundColor: cs.onPrimary,
              foregroundColor: textMuted,
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.settings_suggest_outlined, size: 15),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 15),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 15),
                label: Text('Oscuro'),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).setMode(selection.first),
          ),
        ],
      ),
    );
  }
}

// ─── Banner correo sin verificar ─────────────────────────────────────────────

class _UnverifiedBanner extends ConsumerWidget {
  const _UnverifiedBanner({required this.authProvider});

  final ProviderBase<AuthRepository> authProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oroAndino.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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
                  style: AppTypography.caption(color: AppColors.oroAndino),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(authProvider).resendVerification();
                if (!context.mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Correo de verificación enviado ✅'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
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
    );
  }
}
