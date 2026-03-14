part of 'user_profile_bloc.dart';

@immutable
sealed class UserProfileEvent {}

class LoadUserProfile extends UserProfileEvent {}

class ResetUserProfile extends UserProfileEvent {}
