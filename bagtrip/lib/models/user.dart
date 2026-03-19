import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String email,
    @JsonKey(name: 'fullName') String? fullName,
    String? phone,
    @JsonKey(name: 'stripeCustomerId') String? stripeCustomerId,
    @JsonKey(name: 'isProfileCompleted')
    @Default(false)
    bool isProfileCompleted,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
    @JsonKey(name: 'updatedAt') DateTime? updatedAt,
    @Default('FREE') String plan,
    @JsonKey(name: 'aiGenerationsRemaining') int? aiGenerationsRemaining,
    @JsonKey(name: 'planExpiresAt') DateTime? planExpiresAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool get isFree => plan == 'FREE';
  bool get isPremium => plan == 'PREMIUM' || plan == 'ADMIN';
  bool get isAdmin => plan == 'ADMIN';
}
