import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';
import 'artist_public_profile_screen/profile_body.dart';

class ArtistPublicProfileScreen extends ConsumerStatefulWidget {
  final String artistId;
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
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.obsidiana,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.oroClaro),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.indigoClaro),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.obsidiana,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.oroClaro),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined,
                    size: 56, color: AppColors.indigoClaro),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar el perfil',
                  style: AppTypography.bodyMedium(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profile) {
        if (!_loadingFollow) _isFollowing = profile.esSeguido;
        return ProfileBody(
          profile: profile,
          isFollowing: _isFollowing,
          loadingFollow: _loadingFollow,
          onToggleFollow: _toggleFollow,
        );
      },
    );
  }

  Future<void> _toggleFollow(String profileId, bool follow) async {
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
      ref.invalidate(myFollowingProvider);
    } catch (_) {
      setState(() => _loadingFollow = false);
    }
  }
}
