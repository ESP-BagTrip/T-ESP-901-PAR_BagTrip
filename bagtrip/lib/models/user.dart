import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String email,
    String? fullName,
    String? phone,
    String? stripeCustomerId,
    @Default(false) bool isProfileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default('FREE') String plan,
    int? aiGenerationsRemaining,
    DateTime? planExpiresAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool get isFree => plan == 'FREE';
  bool get isPremium => plan == 'PREMIUM' || plan == 'ADMIN';
  bool get isAdmin => plan == 'ADMIN';
}
