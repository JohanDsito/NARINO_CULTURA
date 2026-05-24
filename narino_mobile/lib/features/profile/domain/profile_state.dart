import 'profile_model.dart';
import 'portfolio_item_model.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.portfolio = const [],
    this.errorMessage,
    this.isSaving = false,
    this.photoVersion = 0,
  });

  final ProfileStatus status;
  final ProfileModel? profile;
  final List<PortfolioItemModel> portfolio;
  final String? errorMessage;
  final bool isSaving;
  // Incrementado cada vez que se sube una nueva foto; sirve para invalidar
  // el cache de imagen en los widgets que muestran el avatar.
  final int photoVersion;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileModel? profile,
    List<PortfolioItemModel>? portfolio,
    String? errorMessage,
    bool clearError = false,
    bool? isSaving,
    int? photoVersion,
  }) =>
      ProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        portfolio: portfolio ?? this.portfolio,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isSaving: isSaving ?? this.isSaving,
        photoVersion: photoVersion ?? this.photoVersion,
      );

  bool get isLoading => status == ProfileStatus.loading;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
