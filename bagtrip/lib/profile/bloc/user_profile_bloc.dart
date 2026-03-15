import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/profile_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  }) : _authRepository = authRepository ?? getIt<AuthRepository>(),
       _profileRepository = profileRepository ?? getIt<ProfileRepository>(),
       super(UserProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<ResetUserProfile>(_onResetUserProfile);
  }

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(UserProfileLoading());

    final userResult = await _authRepository.getCurrentUser();
    if (isClosed) return;

    switch (userResult) {
      case Success(:final data):
        final user = data;
        if (user == null) {
          await _authRepository.logout();
          if (isClosed) return;
          emit(
            UserProfileError(
              error: const AuthenticationError('Session expirée'),
            ),
          );
          return;
        }

        List<String> travelTypes = [];
        String? travelStyle;
        String? budget;
        String? companions;
        final profileResult = await _profileRepository.getProfile();
        if (isClosed) return;
        if (profileResult is Success) {
          final travelerProfile = (profileResult as Success).data;
          travelTypes = travelerProfile.travelTypes;
          travelStyle = travelerProfile.travelStyle;
          budget = travelerProfile.budget;
          companions = travelerProfile.companions;
        }

        final memberSince = user.createdAt ?? DateTime.now();

        emit(
          UserProfileLoaded(
            name: user.fullName?.trim().isNotEmpty == true
                ? user.fullName!
                : user.email,
            email: user.email,
            phone: user.phone?.trim().isNotEmpty == true ? user.phone! : '—',
            address: '—',
            memberSince: memberSince,
            travelTypes: travelTypes,
            travelStyle: travelStyle,
            budget: budget,
            companions: companions,
          ),
        );
      case Failure(:final error):
        if (error is AuthenticationError) {
          await _authRepository.logout();
          if (isClosed) return;
        }
        emit(UserProfileError(error: error));
    }
  }

  void _onResetUserProfile(
    ResetUserProfile event,
    Emitter<UserProfileState> emit,
  ) {
    emit(UserProfileInitial());
  }
}
