import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/profile_repository.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
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
    on<UpdateUserName>(_onUpdateUserName);
    on<UpdateUserPhone>(_onUpdateUserPhone);
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
        if (profileResult case Success(:final data)) {
          travelTypes = data.travelTypes;
          travelStyle = data.travelStyle;
          budget = data.budget;
          companions = data.companions;
        }

        final memberSince = user.createdAt ?? DateTime.now();

        emit(
          UserProfileLoaded(
            name: user.fullName?.trim().isNotEmpty == true
                ? user.fullName!
                : user.email,
            email: user.email,
            phone: user.phone?.trim().isNotEmpty == true ? user.phone! : '—',
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

  Future<void> _onUpdateUserName(
    UpdateUserName event,
    Emitter<UserProfileState> emit,
  ) async {
    final current = state;
    if (current is! UserProfileLoaded) return;

    emit(current.copyWith(isUpdating: true));

    final result = await _authRepository.updateUser(fullName: event.name);
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        final name = data.fullName?.trim().isNotEmpty == true
            ? data.fullName!
            : data.email;
        emit(current.copyWith(name: name, isUpdating: false));
      case Failure(:final error):
        getIt<CrashlyticsService>().recordAppError(error);
        emit(current.copyWith(isUpdating: false));
    }
  }

  Future<void> _onUpdateUserPhone(
    UpdateUserPhone event,
    Emitter<UserProfileState> emit,
  ) async {
    final current = state;
    if (current is! UserProfileLoaded) return;

    emit(current.copyWith(isUpdating: true));

    final result = await _authRepository.updateUser(phone: event.phone);
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        final phone = data.phone?.trim().isNotEmpty == true ? data.phone! : '—';
        emit(current.copyWith(phone: phone, isUpdating: false));
      case Failure(:final error):
        getIt<CrashlyticsService>().recordAppError(error);
        emit(current.copyWith(isUpdating: false));
    }
  }
}
