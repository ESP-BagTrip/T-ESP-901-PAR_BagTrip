import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:bagtrip/models/user.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    @Default('') String refreshToken,
    @Default(3600) int expiresIn,
    required User user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
