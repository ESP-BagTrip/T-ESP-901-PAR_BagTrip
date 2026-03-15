part of 'user_profile_bloc.dart';

@immutable
sealed class UserProfileEvent {}

class LoadUserProfile extends UserProfileEvent {}

class ResetUserProfile extends UserProfileEvent {}

class UpdateUserName extends UserProfileEvent {
  final String name;
  UpdateUserName(this.name);
}

class UpdateUserPhone extends UserProfileEvent {
  final String phone;
  UpdateUserPhone(this.phone);
}
