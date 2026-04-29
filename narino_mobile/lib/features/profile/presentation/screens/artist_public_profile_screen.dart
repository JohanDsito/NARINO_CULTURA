import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';

class ArtistPublicProfileScreen extends ConsumerStatefulWidget {
  final int artistId;
  const ArtistPublicProfileScreen({super.key, required this.artistId});

  @override
  ConsumerState<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState
    extends ConsumerState<ArtistPublicProfileScreen> {
  bool _isFollowing = false;
  bool _loadingFollow = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(artistProfileProvider(widget.artistId));

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.tierraProfunda),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No se pudo cargar el perfil')),
      ),
      data: (profile) {
        if (!_loadingFollow) _isFollowing = profile.esSeguido;
        return _buildProfile(context, profile);
      },
    );
  }

  Widget _buildProfile(BuildContext context, ProfileModel profile) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.obsidiana,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.obsidiana,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.tierraPalida,
                        backgroundImage: profile.fotoUrl != null
                            ? NetworkImage(profile.fotoUrl!)
                            : null,
                        child: profile.fotoUrl == null
                            ? Text(
                                profile.nombreArtistico[0].toUpperCase(),
                                style: AppTypography.displayBold(
                                  color: AppColors.tierraProfunda,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.nombreArtistico,
                        style: AppTypography.displaySemiBold(
                          color: AppColors.oroClaro,
                        ),
                      ),
                      Text(
                        profile.disciplina,
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
                      _buildStat('${profile.seguidores}', 'Seguidores'),
                      const SizedBox(width: 20),
                      _buildStat('${profile.obrasDisponibles}', 'Obras'),
                      const Spacer(),
                      SizedBox(
                        height: 38,
                        child: _isFollowing
                            ? OutlinedButton(
                                onPressed: _loadingFollow
                                    ? null
                                    : () => _toggleFollow(profile.id, false),
                                child: Text(
                                  'Siguiendo',
                                  style: AppTypography.labelMedium(
                                    color: AppColors.tierraProfunda,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _loadingFollow
                                    ? null
                                    : () => _toggleFollow(profile.id, true),
                                child: Text(
                                  'Seguir',
                                  style: AppTypography.labelMedium(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  if (profile.biografia != null &&
                      profile.biografia!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    Text(
                      profile.biografia!,
                      style: AppTypography.quoteItalic(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                  if (profile.redesSociales.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    Text(
                      'Redes sociales',
                      style: AppTypography.labelSemiBold(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: profile.redesSociales.entries.map((e) {
                        return ActionChip(
                          label: Text(
                            e.key,
                            style: AppTypography.caption(
                              color: AppColors.tierraProfunda,
                            ),
                          ),
                          onPressed: () async {
                            final uri = Uri.tryParse(e.value);
                            if (uri == null) return;
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  Text(
                    'Obras de ${profile.nombreArtistico}',
                    style: AppTypography.displaySemiBold(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.palette_outlined),
                    label: Text(
                      'Ver todas las obras (${profile.totalObras})',
                      style: AppTypography.labelMedium(
                        color: AppColors.tierraProfunda,
                      ),
                    ),
                    onPressed: () => context.go('/catalog'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow(int profileId, bool follow) async {
    setState(() => _loadingFollow = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      if (follow) {
        await repo.followArtist(profileId);
      } else {
        await repo.unfollowArtist(profileId);
      }
      setState(() {
        _isFollowing = follow;
        _loadingFollow = false;
      });
      ref.invalidate(artistProfileProvider(profileId));
    } catch (_) {
      setState(() => _loadingFollow = false);
    }
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style:
              AppTypography.displaySemiBold(color: AppColors.textPrimaryLight)
                  .copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: AppTypography.caption(color: AppColors.textMutedLight),
        ),
      ],
    );
  }
}
