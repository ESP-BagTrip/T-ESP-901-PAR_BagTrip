part of 'user_profile_bloc.dart';

@immutable
sealed class UserProfileState {}

final class UserProfileInitial extends UserProfileState {}

final class UserProfileLoading extends UserProfileState {}

final class UserProfileLoaded extends UserProfileState {
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime memberSince;
  final List<String> travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;

  UserProfileLoaded({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.memberSince,
    this.travelTypes = const [],
    this.travelStyle,
    this.budget,
    this.companions,
  });
}

final class UserProfileError extends UserProfileState {
  final AppError error;

  UserProfileError({required this.error});
}
