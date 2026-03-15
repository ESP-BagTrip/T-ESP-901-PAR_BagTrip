part of 'user_profile_bloc.dart';

@immutable
sealed class UserProfileState {}

final class UserProfileInitial extends UserProfileState {}

final class UserProfileLoading extends UserProfileState {}

final class UserProfileLoaded extends UserProfileState {
  final String name;
  final String email;
  final String phone;
  final DateTime memberSince;
  final List<String> travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;
  final bool isUpdating;

  UserProfileLoaded({
    required this.name,
    required this.email,
    required this.phone,
    required this.memberSince,
    this.travelTypes = const [],
    this.travelStyle,
    this.budget,
    this.companions,
    this.isUpdating = false,
  });

  UserProfileLoaded copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? memberSince,
    List<String>? travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
    bool? isUpdating,
  }) {
    return UserProfileLoaded(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      memberSince: memberSince ?? this.memberSince,
      travelTypes: travelTypes ?? this.travelTypes,
      travelStyle: travelStyle ?? this.travelStyle,
      budget: budget ?? this.budget,
      companions: companions ?? this.companions,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

final class UserProfileError extends UserProfileState {
  final AppError error;

  UserProfileError({required this.error});
}
