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
  });

  final ProfileStatus status;
  final ProfileModel? profile;
  final List<PortfolioItemModel> portfolio;
  final String? errorMessage;
  final bool isSaving;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileModel? profile,
    List<PortfolioItemModel>? portfolio,
    String? errorMessage,
    bool clearError = false,
    bool? isSaving,
  }) =>
      ProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        portfolio: portfolio ?? this.portfolio,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isSaving: isSaving ?? this.isSaving,
      );

  bool get isLoading => status == ProfileStatus.loading;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
