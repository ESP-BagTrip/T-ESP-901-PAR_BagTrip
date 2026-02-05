part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

class LoadProfile extends ProfileEvent {}

class UpdateTheme extends ProfileEvent {
  final String theme; // 'light', 'dark', 'system'

  UpdateTheme(this.theme);
}

class UpdateLanguage extends ProfileEvent {
  final String language;

  UpdateLanguage(this.language);
}

class SetDefaultPaymentMethod extends ProfileEvent {
  final String cardId;

  SetDefaultPaymentMethod(this.cardId);
}
