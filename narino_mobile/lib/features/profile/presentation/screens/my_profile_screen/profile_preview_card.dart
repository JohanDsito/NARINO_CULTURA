import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/user_role_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/app_avatar.dart';
import '../../../domain/profile_model.dart';
import '../../providers/profile_provider.dart';
import 'role_badge.dart';
import 'stat.dart';
import 'stat_divider.dart';

// ─── Tarjeta de vista previa pública ─────────────────────────────────────────

class ProfilePreviewCard extends ConsumerWidget {
  const ProfilePreviewCard({
    super.key,
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3D2410), AppColors.obsidiana],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  children: [
                    // Anillo dorado alrededor del avatar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.oroClaro, AppColors.oroAndino],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: AppAvatar(
                        key: ValueKey('avatar-$photoVersion'),
                        radius: 46,
                        url: profile?.fotoUrl,
                        initials: profile?.nombreArtistico.isNotEmpty == true
                            ? profile!.nombreArtistico
                            : '?',
                      ),
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
                      RoleBadge(role: role),
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
                    Stat(
                      value: '${profile?.seguidores ?? 0}',
                      label: 'Seguidores',
                    ),
                    const StatDivider(),
                    Stat(
                      value: '${profile?.totalObras ?? 0}',
                      label: 'Obras',
                    ),
                    const StatDivider(),
                    Stat(
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

            ],
          ),
        ),
      ],
    );
  }
}
